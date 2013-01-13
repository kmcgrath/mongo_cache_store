# -*- encoding : utf-8 -*-

require 'active_support/cache/mongo_cache_store/backend/base'

module ActiveSupport
  module Cache
    class MongoCacheStore
      module Backend
        # MongoCacheStoreBackend for capped collections 
        #  
        # == Capped Collections
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
