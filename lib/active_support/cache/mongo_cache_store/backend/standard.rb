# -*- encoding : utf-8 -*-

require 'active_support/cache/mongo_cache_store/backend/base'


module ActiveSupport
  module Cache
    class MongoCacheStore
      module Backend
        # == Standard 
        #
        # Standard backend for MongoCacheStore
        #  
        # === Description
        #
        # Entreis are kept in a namespaced MongoDB collection. In a standard 
        # collection entries are only flushed from the collection with an 
        # explicit delete call or if auto_flush is enabled.  If auto_flush is 
        # enabled the cache will flush all expired entries when auto\_flush\_threshold 
        # is reached.  The threshold is based on a set number of cache instance writes. 
        #
        # === Additional Options  
        #  
        # The following options can be added to a MongoCacheStore constructor
        #
        # [+options+ - Standard backend options] 
        #     To see a list of core options see MongoCacheStore
        #     [+:auto_flush+ - *true* | false]
        #         Default: true
        #
        #         If auto_flush is enabled the cache will flush all 
        #         expired entries when auto\_flush\_threshold
        #         is reached.
        #     [+:auto_flush_threshold+ - *10_000*] 
        #         Default: 10_000
        #
        #         A number representing the number of writes the when the cache 
        #         should preform before flushing expired entries.
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
