# -*- encoding : utf-8 -*-

require 'active_support/cache/mongo_cache_store/backend/base'


module ActiveSupport
  module Cache
    class MongoCacheStore
      module Backend
        # MongoCacheStoreBackend for standard collections 
        #  
        # == Standard collections 
        #
        module Standard
          include Base

          def clear(options = {})
            col = get_collection(options) 
            ret = safe_rescue do
              col.remove
            end
            ret ? true : false
          end

          private 

          def backend_name
            "standard"
          end

          def get_collection(options)
            @db[get_collection_name(options)]
          end

          def write_entry(key, entry, options)
            ret = super
            @write_cnt += 1
            if options[:auto_flush] and @write_cnt > options[:auto_flush_threshold]
              safe_rescue do
                col = get_collection(options)
                col.delete({
                  :expires_at => {
                    '$gt' => Time.now 
                  }
                })
              end
              @write_cnt = 0
            end
            return ret
          end

          def build_backend(options)
            options.replace({
              :auto_flush => true,
              :auto_flush_threshold => 10_000,
              :collection => nil
            }.merge(options))

            @write_cnt = 0
          end
        end
      end
    end
  end
end
