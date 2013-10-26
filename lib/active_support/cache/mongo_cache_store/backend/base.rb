# -*- encoding : utf-8 -*-

module ActiveSupport
  module Cache
    class MongoCacheStore
      module Backend
        # Base methods used by all MongoCacheStore backends 
        module Base 


          def increment(name, amount = 1, options = {})
            write_counter(name,amount.to_i,options)
          end

          def decrement(name, amount = 1, options = {})
            write_counter(name,amount.to_i*-1,options)
          end

          def read_multi(*names)
            options = names.extract_options!
            options = merged_options(options)
            results = {}

            col = get_collection(options)

            key_map = names.inject({}) do |h, name|
              h[namespaced_key(name,options)] = name
              h
            end

            safe_rescue do
              query = {
                :_id => { '$in' => key_map.keys},
                :expires_at => {
                  '$gt' => Time.now
                }
              }

              col.find(query) do |cursor|
                cursor.each do |r| 
                  results[key_map[r['_id']]] = inflate_entry(r).value
                end
              end
            end

            results
          end

          def delete_matched(matcher, options = nil)
            col = get_collection(options)
            safe_rescue do
              col.remove({'_id' => matcher})
            end
          end

          private 

            def expanded_key(key)
              return key.cache_key.to_s if key.respond_to?(:cache_key)

              case key
              when Array
                if key.size > 1
                  key = key.collect{|element| expanded_key(element)}
                else
                  key = key.first
                end
              when Hash
                return key 
              end

              key.to_param
            end

            def namespaced_key(key, options)
              key = expanded_key(key)
              key = key.join('/') if key.is_a?(Array)
              key = key.cache_key if key.methods.include?(:cache_key)

              return key 
            end

            def read_entry(key,options)
              col = get_collection(options)

              safe_rescue do
                query = {
                  :_id => key,
                  :expires_at => {
                    '$gt' => Time.now
                  },
                  :data_store_version => ::MongoCacheStore::DATA_STORE_VERSION
                }

                response = col.find_one(query)
                return inflate_entry(response)
              end
              nil
            end


            def inflate_entry(from_mongo)
                return nil if from_mongo.nil?

                case from_mongo['value']
                when BSON::Binary
                  fm = Marshal.load(from_mongo['value'].to_s)
                  case fm
                  when Entry
                    if from_mongo['raw_value'].nil? == false
                      fm.instance_eval { @value = from_mongo['raw_value'] }
                    end
                    fm
                  end
                end
            end

            def write_counter(name, amount, options)
              col = get_collection(options)
              key = namespaced_key(name,options) 

              safe_rescue do
                doc = col.find_and_modify(
                  :query => {
                    :_id => key,
                    :data_store_version => ::MongoCacheStore::DATA_STORE_VERSION
                  },
                  :update => {
                    :$inc => {
                      :raw_value => amount
                    }
                  }
                )

                return nil unless doc
                doc['raw_value'] + amount
              end
            end

            def write_entry(key,entry,options)
              col = get_collection(options)
              serialize = options[:serialize] == :always ? true : false
              serialize = false if entry.value.is_a?(Integer) || entry.value.nil?

              value = BSON::Binary.new(Marshal.dump(entry))
              unless entry.send(:compressed?) || serialize
                raw_value = entry.value
                entry.instance_eval { @value = nil }
              end

              try_cnt = 0

              save_doc = {
                :_id => key,
                :created_at => Time.at(entry.instance_eval { @created_at}),
                :expires_in => entry.instance_eval { @expires_in },
                :expires_at => entry.expires_at.nil? ? Time.utc(9999) : Time.at(entry.expires_at),
                :compressed => entry.send( :compressed? ),
                :serialized => serialize,
                :value => value,
                :raw_value => raw_value,
                :data_store_version => ::MongoCacheStore::DATA_STORE_VERSION
              }.merge(options[:xentry] || {})

              safe_rescue do
                begin
                  col.save(save_doc)
                rescue BSON::InvalidDocument
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
              name_parts.push options[:namespace] if !options[:namespace].nil?
              name = name_parts.join('.')
              return name
            end

            def get_collection(options)
              return options[:collection] if options[:collection].is_a? Mongo::Collection

              @db.collection(get_collection_name(options),options[:collection_opts] || {})
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
