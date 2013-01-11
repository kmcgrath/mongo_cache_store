# -*- encoding : utf-8 -*-
#encoding: utf-8
require "mongo_cache_store/version"
require "mongo"
require "active_support/cache"


module MongoCacheStoreBackend

  # Base methods used by all MongoCacheStore backends 
  module Base

    # No public methods are defined for this module

    private 

      def expand_key(key)
        return key 
      end

      def namespaced_key(key, options)
        return key 
      end

      def read_entry(key,options)
        col = get_collection(options)

        safe_rescue do 
          query = {
            :_id => key,
            :expires_at => {
              '$gt' => Time.now 
            }
          }

          response = col.find_one(query)
          return nil if response.nil?

          entry_options = {
            :compressed => response[:compressed],
            :expires_in => response[:expires_in] 
          }
          if response['serialized']
            r_value = response['value'].to_s
          else
            r_value = Marshal.dump(response['value'])
          end
          ActiveSupport::Cache::Entry.create(r_value,response[:created_at],entry_options)
        end
      end


      def write_entry(key,entry,options)
        col = get_collection(options)
        serialize = options[:serialize] == :always ? true : false
        try_cnt = 0
        now = Time.now

        safe_rescue do
          begin
            col.save({
              :_id => key,
              :created_at => now,
              :expires_in => entry.expires_in,
              :expires_at => entry.expires_in.nil? ? Time.utc(9999) : now + entry.expires_in,
              :compressed => entry.compressed?,
              :serialized => serialize,
              :value      => serialize ? BSON::Binary.new(entry.raw_value) : entry.value 
            })
          rescue BSON::InvalidDocument => ex
            serialize = true
            retry if options[:serialize] == :on_fail and try_cnt < 1
          end
        end
      end

      def delete_entry(key,options)
        col = get_collection(options)
        safe_rescue do
          col.remove({'_id' => key})
        end
      end
    
      def get_collection_name(options = {})
        name_parts = ['cache'] 
        name_parts.push(backend_name)
        name_parts.push options[:namespace] unless options[:namespace].nil?
        return name_parts.join('.')
      end

      def get_collection(options)
        return options[:collection] if options[:collection].is_a? Mongo::Collection
      end

      def safe_rescue
        begin
          yield
        rescue => e
          warn e
          logger.error("FileStoreError (#{e}): #{e.message}") if logger 
          false
        end
      end
  end

  # MongoCacheStoreBackend for capped collections 
  #  
  # == Capped Collections
  #
  module Capped
    include Base

    def clear(options = {})
      col = get_collection(options) 
      safe_rescue do
        col.update({},{:expires_at => Time.new})
      end
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

  # MongoCacheStoreBackend for TTL collections 
  #  
  # == Time To Live (TTL) collections 
  #
  module TTL
    include Base

    alias :get_collection_prefix :get_collection_name

    def clear(options = {})
      @db.collection_names.each do |cname|
        prefix = get_collection_prefix
        if prefix.match(/^cache/) and cname.match(/^#{get_collection_prefix(options)}/)
          @db[cname].drop
        end
      end
    end

    protected

    def read_entry(key, options)
      if options[:expires_in]
        options[:collection] = get_collection(options)
      else
        options[:collection] = get_collection_from_index(key,options)
      end

      super(key, options)
    end


    def write_entry(key, entry, options)
      options[:collection] = get_collection(options)

      super(key, entry, options)

      if (options[:use_index])
        ki  = get_key_index_collection(options)
        indexed = safe_rescue do
          ki.save({
            :_id => key,
            :collection => options[:collection].name
          })
        end
      end

    end

    def delete_entry(key, options)
      options[:collection] = get_collection_from_index(key,options)
      super(key, options)
    end

    

    private 

    def backend_name
      "ttl"
    end

    def get_collection(options)

      col = super 
      return col unless col.nil?

      name_parts = [get_collection_prefix(options)]
      expires_in = options[:expires_in]
      name_parts.push expires_in.nil? ? 'forever' : expires_in.to_i
      collection_name = name_parts.join('.')

      collection = @collection_map[collection_name]

      collection ||= create_collection(collection_name, expires_in) 
      return collection
    end


    def get_key_index_collection(options)
      name_parts = [get_collection_prefix(options)]
      name_parts.push options[:namespace] unless options[:namespace].nil?
      name_parts.push 'key_index'

      @db[name_parts.join('.')]
    end

    def get_collection_from_index(key,options)
      if (options[:use_index])
        ki  = get_key_index_collection(options)

        options[:collection] = safe_rescue do  
          response = ki.find_one({
            :_id => key,
          })
          return nil if response.nil?

          return @db[response['collection']]
        end
      end
      nil
    end


    def create_collection(name, expires_in)
      collection = @db[name]
      collection.ensure_index('created_at',{ expireAfterSeconds: expires_in.to_i }) unless expires_in.nil?
      return collection
    end

    def build_backend(options)
      options.replace({
        :use_index => true
      }.merge(options)) 

      @collection_map = {}
    end

  end


  # MongoCacheStoreBackend for standard collections 
  #  
  # == Standard collections 
  #
  module Standard
    include Base

    def clear(options = {})
      col = get_collection(options) 
      safe_rescue do
        col.remove
      end
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

        extend MongoCacheStoreBackend.const_get(backend)

        build_backend(options)

        super(options)

        if (@db.nil?)
          #TODO 
        end 
      end
    end
  end
end
