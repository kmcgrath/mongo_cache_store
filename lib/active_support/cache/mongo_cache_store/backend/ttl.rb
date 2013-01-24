# -*- encoding : utf-8 -*-

require 'active_support/cache/mongo_cache_store/backend/base'

module ActiveSupport
  module Cache
    class MongoCacheStore
      module Backend
        # == TTL
        #
        # TTL backend for MongoCacheStore
        #
        # === Description
        #
        # Entries are kept in a namespaced TTL collection that will 
        # automatically flush any entries as they pass their expiration 
        # time. This keeps the size of the cache in check over time. 
        #
        # <b>Requires MongoDB 2.0 or higher</b>
        #
        # === Additional Options
        #
        # No additional options at this time
        # 
        module TTL
          include Base

          def clear(options = {})
            col = get_collection(options) 
            ret = safe_rescue do
              col.remove
            end
            @collection = nil
            ret ? true : false
          end

          protected

          def write_entry(key,entry,options)

            # Set all time based entries here.
            # This ensures all fields are based on the same Time
            now = Time.now 
            options[:xentry] = {
              :created_at   => now,
              :expires_at   => entry.expires_in.nil? ? Time.utc(9999) : now + entry.expires_in.to_i
            }

            super(key,entry,options)
          end


          private 

          def backend_name
            "ttl"
          end

          def get_collection(options)
            return @collection if @collection.is_a? Mongo::Collection
            collection = super 
            collection.ensure_index('expires_at',{ expireAfterSeconds: 0 })
            @collection = collection
          end

          def build_backend(options)

          end

        end
      end
    end
  end
end

