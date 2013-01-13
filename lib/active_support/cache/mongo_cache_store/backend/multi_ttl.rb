# -*- encoding : utf-8 -*-

require 'active_support/cache/mongo_cache_store/backend/base'


module ActiveSupport
  module Cache
    class MongoCacheStore
      module Backend
        # MongoCacheStoreBackend for TTL collections 
        #  
        # == Time To Live (TTL) collections 
        #
        module MultiTTL
          include Base

          alias :get_collection_prefix :get_collection_name

          def clear(options = {})
            @db.collection_names.each do |cname|
              prefix = get_collection_prefix
              if prefix.match(/^cache/) and cname.match(/^#{get_collection_prefix(options)}/)
                safe_rescue do
                  @db[cname].drop
                end
              end
            end
            true
          end

          protected

          def read_entry(key, options)
            if options[:expires_in]
              options[:collection] = get_collection(options)
            else
              options[:collection] = get_collection_from_index(key,options)
            end

            super(key, options)
          end


          def write_entry(key, entry, options)
            options[:collection] = get_collection(options)

            super(key, entry, options)

            if (options[:use_index])
              ki  = get_key_index_collection(options)
              indexed = safe_rescue do
                ki.save({
                  :_id => key,
                  :collection => options[:collection].name,
                  :expires_at => entry.expires_at
                })
              end
            end

          end

          def delete_entry(key, options)
            options[:collection] = get_collection_from_index(key,options)
            super(key, options)
          end


          private 

          def backend_name
            "multi_ttl"
          end

          def get_collection(options)

            col = super 
            return col unless col.nil?

            name_parts = [get_collection_prefix(options)]
            expires_in = options[:expires_in]
            name_parts.push expires_in.nil? ? 'forever' : expires_in.to_i
            collection_name = name_parts.join('.')

            collection = @collection_map[collection_name]

            collection ||= create_collection(collection_name, expires_in) 
            return collection
          end


          def get_key_index_collection(options)
            name_parts = [get_collection_prefix(options)]
            name_parts.push options[:namespace] unless options[:namespace].nil?
            name_parts.push 'key_index'

            col = @db[name_parts.join('.')]
            col.ensure_index('expires_at',{ expireAfterSeconds: 0})
            return col
          end

          def get_collection_from_index(key,options)
            if (options[:use_index])
              ki  = get_key_index_collection(options)

              options[:collection] = safe_rescue do  
                response = ki.find_one({
                  :_id => key,
                })
                return nil if response.nil?

                return @db[response['collection']]
              end
            end
            nil
          end


          def create_collection(name, expires_in)
            collection = @db[name]
            collection.ensure_index('created_at',{ expireAfterSeconds: expires_in.to_i }) unless expires_in.nil?
            return collection
          end

          def build_backend(options)
            options.replace({
              :use_index => true
            }.merge(options)) 

            @collection_map = {}
          end

        end
      end
    end
  end
end
