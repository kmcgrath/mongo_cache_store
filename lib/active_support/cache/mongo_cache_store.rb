# -*- encoding : utf-8 -*-
require "mongo_cache_store/version"
require "mongo"
require "active_support/cache"

module ActiveSupport
  module Cache

    class MongoCacheStore < Store

      def initialize (backend=:Standard, options = {})
       
        options = {
          :db_name => 'mongo_cache',
          :db => nil,
          :namespace => nil,
          :serialize => :on_fail
        }.merge(options) 

        @db = options.delete :db

        extend ActiveSupport::Cache::MongoCacheStore::Backend.const_get(backend)

        build_backend(options)

        super(options)

        if (@db.nil?)
          #TODO 
        end 
      end
    end
  end
end

require "active_support/cache/mongo_cache_store/backend/capped"
require "active_support/cache/mongo_cache_store/backend/standard"
require "active_support/cache/mongo_cache_store/backend/ttl"
require "active_support/cache/mongo_cache_store/backend/multi_ttl"