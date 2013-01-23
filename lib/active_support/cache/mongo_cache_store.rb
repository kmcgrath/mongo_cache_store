# -*- encoding : utf-8 -*-
require "mongo_cache_store/version"
require "mongo"
require "active_support/cache"
require "logger"

module ActiveSupport
  module Cache

    class MongoCacheStore < Store

      # Initialize the cache
      #  
      # === Attributes  
      #  
      # [+backend+ - Symbol representing the backend the cache should use] 
      #     :TTL | :Standard | :MultiTTL      
      #
      # [+options+ - Options for ActiveSupport::Cache and the backend] 
      #     Core options are listed here.  See each backend for a list of additional optons. 
      #     [+:db+ - A Mongo::DB instance.]
      #     [+:db_name+ - Name of database to create if no 'db' is given.] 
      #     [+:connection+ - A Mongo::Connection instance. Only used if no 'db' is given.] 
      #     [+:serialize+ - *:always* | :on_fail | :never]
      #         [+:always+ - (default) - Serialize all entries]
      #             *NOTE* Without serialization class structures and instances that cannot 
      #             be converted to a native MongoDB type will not be stored.  Also, 
      #             without serialization MongoDB converts all symbols to strings.  
      #             Therefore a hash with symbols as keys will have strings as keys when read. 
      #
      #         [+:on_fail+ - Serialize if native format fails]
      #             Try to save the entry in a native MongoDB format.  If that fails, 
      #             then serialize the entry. 
      #         [+:never+ - Never serialize]
      #             Only save the entry if it can be saved natively by MongoDB.
      #     [+:collection_opts+ ]
      #         Hash of options passed directly to MongoDB::Collection.
      #           
      #         Useful for write conditions and read preferences
      #
      # === Examples
      #     @store = ActiveSupport::Cache::MongoCacheStore.new(:TTL, :db => Mongo::DB.new('db_name',Mongo::Connection.new))
      #
      #     @store = ActiveSupport::Cache::MongoCacheStore.new(:Standard, :db_name => 'db_name', :connection => Mongo::Connection.new)    
        
      def initialize (backend=:Standard, options = {})
       
        options = {
          :db_name => 'cache_store',
          :db => nil,
          :namespace => nil,
          :connection => nil,
          :serialize => :always,
          :collection_opts => {}
        }.merge(options) 

        @db = options.delete :db
        @logger = options.delete :logger

        if (@db.nil?)
          @db = Mongo::DB.new(options[:db_name], options[:connection] || Mongo::Connection.new)
        end 



        extend ActiveSupport::Cache::MongoCacheStore::Backend.const_get(backend)

        build_backend(options)

        super(options)

      end

      def logger
        return @logger unless @logger.nil?

        slogger = super
        case
        when !slogger.nil?
          @logger = slogger
        when defined?(Rails) && Rails.logger
          @logger = Rails.logger
        else
          @logger = Logger.new(STDOUT)
        end
      
        @logger
      end
  
    end
  end
end

require "active_support/cache/mongo_cache_store/backend/capped"
require "active_support/cache/mongo_cache_store/backend/standard"
require "active_support/cache/mongo_cache_store/backend/ttl"
require "active_support/cache/mongo_cache_store/backend/multi_ttl"