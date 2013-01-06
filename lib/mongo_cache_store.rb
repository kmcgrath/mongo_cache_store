require "mongo_cache_store/version"
require "mongo"
require "active_support"


module MongoCacheStoreBackend
  module Capped
  end

  module TTL

    protected

    def read_entry(key, options)
      col = nil?

      if (@use_index)
        ki  = get_key_index_collection(options)
        col = begin
          response = ki.find_one({
            :_id => key,
          })
          return nil if response.nil?

          @db[response['collection']]
 
        rescue Mongo::ConnectionFailure => ex
          false
        end
      end

      col ||= get_collection(options)

      begin
        response = col.find_one(_id: key)
        return nil if response.nil?
        ActiveSupport::Cache::Entry.create(response['value'], response['created_at'].to_f, response)
      rescue Mongo::ConnectionFailure => ex
        nil
      end
       
    end

    def write_entry(key, entry, options)

      col = get_collection(options)

      if (@use_index)
        ki  = get_key_index_collection(options)
        indexed = begin
          ki.save({
            :_id => key,
            :collection => col.name
          })
        rescue Mongo::ConnectionFailure => ex
          false
        end
        return indexed unless indexed
      end

      begin 
        col.save({
          :_id => key,
          :created_at => Time.now,
          :expires_in => entry.expires_in,
          :compressed => entry.compressed?,
          :value      => entry.raw_value 
        })
      rescue Mongo::ConnectionFailure => ex
        false
      end
    end

    def delete_entry(key, options)

    end


    private 

    def expand_key(key)
      return key 
    end

    def namespaced_key(key, options)
      return key 
    end

    def get_collection(options)
      name_parts = ['cache'] 
      name_parts.push options[:namespace] unless options[:namespace].nil?

      expires_in = options[:expires_in].nil? ? 'forever' : options[:expires_in].to_f
      name_parts.push expires_in.nil? ? 'forever' : expires_in.to_s.sub('.','_') 
      collection_name = name_parts.join('.')

      collection = @collection_map[collection_name]

      collection ||= create_collection(collection_name, expires_in) 
      return collection
    end

    def get_key_index_collection(options)
      name_parts = ['cache']
      name_parts.push options[:namespace] unless options[:namespace].nil?
      name_parts.push 'key_index'

      @db[name_parts.join('.')]
    end


    def create_collection(name, expires_in)
      collection = @db[name]
      collection.ensure_index('created_at',{ expireAfterSeconds: expires_in })
      return collection
    end

    def build_backend(options = {})
      options = {
        :use_index => true
      }.merge(options) 

      @use_index = options[:use_index]
      @collection_map = {}

    end

  end

  module Standard
  end

end

module ActiveSupport
  module Cache

    class MongoCacheStore < Store

      def initialize (backend=:Default, options = {})
       
        options = {
          :db_name => 'mongo_cache',
          :db => nil,
          :namespace => nil
        }.merge(options) 

        @db = options.delete :db

        self.class.send(:include, MongoCacheStoreBackend.const_get(backend))

        build_backend(options)

        super(options)

        if (@db.nil?)
          #TODO 
        end 
      end

    end
  end
end
