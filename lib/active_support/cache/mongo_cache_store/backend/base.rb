# -*- encoding : utf-8 -*-

module ActiveSupport
  module Cache
    class MongoCacheStore
      module Backend
        # Base methods used by all MongoCacheStore backends 
        module Base 

          # No public methods are defined for this module

          private 

            def expand_key(key)
              return key 
            end

            def namespaced_key(key, options)
              return key 
            end

            def read_entry(key,options)
              col = get_collection(options)

              safe_rescue do 
                query = {
                  :_id => key,
                  :expires_at => {
                    '$gt' => Time.now 
                  }
                }

                response = col.find_one(query)
                return nil if response.nil?

                entry_options = {
                  :compressed => response[:compressed],
                  :expires_in => response[:expires_in] 
                }
                if response['serialized']
                  r_value = response['value'].to_s
                else
                  r_value = Marshal.dump(response['value'])
                end
                ActiveSupport::Cache::Entry.create(r_value,response[:created_at],entry_options)
              end
            end


            def write_entry(key,entry,options)
              col = get_collection(options)
              serialize = options[:serialize] == :always ? true : false
              try_cnt = 0

              save_doc = {
                :_id => key,
                :created_at => Time.at(entry.created_at),
                :expires_in => entry.expires_in,
                :expires_at => entry.expires_in.nil? ? Time.utc(9999) : Time.at(entry.expires_at),
                :compressed => entry.compressed?,
                :serialized => serialize,
                :value      => serialize ? BSON::Binary.new(entry.raw_value) : entry.value 
              }.merge(options[:xentry] || {})

              safe_rescue do
                begin
                  col.save(save_doc)
                rescue BSON::InvalidDocument => ex
                  if (options[:serialize] == :on_fail and try_cnt < 2)
                    save_doc[:serialized] = true
                    save_doc[:value] = BSON::Binary.new(entry.raw_value)
                    try_cnt += 1
                    retry 
                  end
                end
              end
            end

            def delete_entry(key,options)
              col = get_collection(options)
              safe_rescue do
                col.remove({'_id' => key})
              end
            end
          
            def get_collection_name(options = {})
              name_parts = ['cache'] 
              name_parts.push(backend_name)
              name_parts.push options[:namespace] unless options[:namespace].nil?
              name = name_parts.join('.')
              return name
            end

            def get_collection(options)
              return options[:collection] if options[:collection].is_a? Mongo::Collection

              @db.collection(get_collection_name(options),options[:collection_opts])
            end

            def safe_rescue
              begin
                yield
              rescue => e
                warn e
                logger.error("MongoCacheStoreError (#{e}): #{e.message}") if logger 
                false
              end
            end
        end
      end
    end
  end
end
