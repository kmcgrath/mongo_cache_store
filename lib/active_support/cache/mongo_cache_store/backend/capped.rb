# -*- encoding : utf-8 -*-

require 'active_support/cache/mongo_cache_store/backend/base'

module ActiveSupport
  module Cache
    class MongoCacheStore
      module Backend
        # == Capped
        # 
        # *Experimental*
        #
        # Capped backend for MongoCacheStore
        #
        # === Description
        # *Experimental* do not use... yet.
        # 
        # This should only be used if limiting the size of the cache 
        # is of great concern.  Entries are flushed from the cache on 
        # a FIFO basis, regardless of the entries expiration time.  
        # Delete operations set an entry to expired, but it will not 
        # be flushed until it is automatically removed by MongoDB.
        #  
        # === Options
        #
        # TODO
        # 
        module Capped
          include Base

          def clear(options = {})
            col = get_collection(options) 
            ret = safe_rescue do
              col.update({},{:expires_at => Time.new})
            end
            ret ? true : false
          end

          private 

          def backend_name
            "capped"
          end

          def get_collection(options)
            @db[get_collection_name(options)]
          end

          def delete_entry(key,options)
            col = get_collection(options)
            safe_rescue do
              col.update({:_id => key}, {:expires_at => Time.new})
            end
          end
        end
      end
    end
  end
end
