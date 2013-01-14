# -*- encoding : utf-8 -*-

require 'active_support/cache/mongo_cache_store/backend/base'


module ActiveSupport
  module Cache
    class MongoCacheStore
      module Backend
        # == MultiTTL 
        #
        # MultiTTL backend for MongoCacheStore
        #  
        # === Description
        #
        # Entries are stored in multiple namespaced TTL collections. 
        # A namespaced TTL collection is created for each unique expiration time.  
        # For example all entries with an expiration time of 300 seconds will be 
        # kept in the same collection while entries with a 900 second expiration 
        # time will be kept in another.  This requires the use of a *key index* 
        # collection that keeps track of which TTL collection a entry resides in. 
        #
        # ==== Downsides
        # * Cache set operations require 2 MongoDB write calls.  
        #   One for the key index, one for the TTL collection. 
        #   (unless *use_index* is false, see below)
        # * Cache read operations will require 1 or 2 MongoDB calls 
        #   depending on whether the 'expires_in' option is set for the read.
        #
        # ==== Benefits (future)
        # * Ability to flush cache based on expire time (TODO)
        #
        #
        # === Additional Options  
        #  
        # The following options can be added to a MongoCacheStore constructor
        #
        # [+options+ - MultiTTL backend options] 
        #     To see a list of core options see MongoCacheStore
        #     [+:use_index+ - *true* | false]
        #         Default: true
        #
        #         This should only be set to *false* if all fetch and/or read 
        #         operations are passed the *:expires_in* option.  If so, this 
        #         will eliminate the need for the key index collection and only 
        #         one write and one read operation is necessary. 
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
