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
        query = {
          :_id => key,
          :expires_at => {
            '$gt' => Time.now 
          }
        }

        response = col.find_one(query)
        return nil if response.nil?
        value = response.delete('value')
        ActiveSupport::Cache::Entry.new(response['serialized'] ? Marshal.load(value) : value, response)
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
          warn "MongoCacheStore Connection Error"
          false
        end
        return indexed if indexed.nil?
      end

      serialize = false
      try_cnt = 0
      begin 
        try_cnt += 1
        now = Time.now
        col.save({
          :_id => key,
          :created_at => now,
          :expires_in => entry.expires_in,
          :expires_at => entry.expires_in.nil? ? Time.utc(9999) : now + entry.expires_in,
          :compressed => entry.compressed?,
          :serialized => serialize,
          :value      => serialize ? Marshal.dump(entry.value) : entry.value 
        })
      rescue Mongo::ConnectionFailure => ex
        false
      rescue BSON::InvalidDocument => ex
        serialize = true
        retry unless try_cnt > 1
        raise ex
      end
    end

    def delete_entry(key, options)
      col = get_collection(options) 
      begin
        col.remove({'_id' => key})
      rescue Mongo::ConnectionFailure => ex
        false
      end
    end


    

    private 

    def get_collection(options)
      name_parts = ['cache'] 
      name_parts.push options[:namespace] unless options[:namespace].nil?

      expires_in = options[:expires_in]
      name_parts.push expires_in.nil? ? 'forever' : expires_in.to_i
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
      collection.ensure_index('created_at',{ expireAfterSeconds: expires_in.to_i }) unless expires_in.nil?
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


      private 

      def expand_key(key)
        return key 
      end

      def namespaced_key(key, options)
        return key 
      end

    end
  end
end
