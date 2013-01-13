# -*- encoding : utf-8 -*-
require "mongo_cache_store/version"
require "mongo"
require "active_support/cache"

module ActiveSupport
  module Cache

    class MongoCacheStore < Store

      def initialize (backend=:Standard, options = {})
       
        options = {
          :db_name => 'cache_store',
          :db => nil,
          :namespace => nil,
          :connection => nil,
          :serialize => :always
        }.merge(options) 

        @db = options.delete :db

        if (@db.nil?)
          @db = Mongo::DB.new(options[:db_name], options[:connection] || Mongo::Connection.new)
        end 

        extend ActiveSupport::Cache::MongoCacheStore::Backend.const_get(backend)

        build_backend(options)

        super(options)

      end
    end
  end
end

require "active_support/cache/mongo_cache_store/backend/capped"
require "active_support/cache/mongo_cache_store/backend/standard"
require "active_support/cache/mongo_cache_store/backend/ttl"
require "active_support/cache/mongo_cache_store/backend/multi_ttl"