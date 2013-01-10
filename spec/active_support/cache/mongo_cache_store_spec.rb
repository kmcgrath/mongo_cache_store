require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper')


class MongoCacheStoreTestSaveClass

  attr_reader :set_me
  def initialize(set_me)
    @set_me = set_me
  end

end


module ActiveSupport 
  module Cache
    shared_examples "a cache store" do
      describe "Caching" do
    
        it "can write values" do
          @store.write('forever!', 'I live forever!')
          @store.fetch('forever!').should == "I live forever!"
        end

        it "can expire" do
          @store.fetch 'fnord', expires_in: 10.seconds do 
            "I am vaguely disturbed."
          end
          @store.exist?("fnord").should == true

          sleep 11 

          response = @store.fetch 'fnord'
          response.should == nil
        end

        it "can cache a hash" do
          @store.write('hashme',
            {
              :one => 1,
              :two => 'two',
              :three => :three
            },
            expires_in: 1.hour
          )

          hash = @store.read('hashme')
          hash[:one].should == 1

        end

        it "can cache class instances" do
          @store.fetch 'my_class', expires_in: 30.seconds do
            MongoCacheStoreTestSaveClass.new('what did i say?')
          end

          my_class = @store.fetch 'my_class'
          my_class.set_me.should == 'what did i say?'
        end

        it "can use a hash as a key" do
          hash_key = {
            :class_name => 'my_class',
            :option2 => 2
          }

          miss_key = {
            :class_name => 'my_class',
            :option2 => 1
          }

          hit_key = {
            :class_name => 'my_class',
            :option2 => 2
          }


          @store.fetch(hash_key, expires_in: 30.seconds) do
            MongoCacheStoreTestSaveClass.new('what did i say?')
          end

          my_class = @store.fetch(hash_key)
          my_class.set_me.should == 'what did i say?'

          my_class = @store.fetch(hit_key)
          my_class.set_me.should == 'what did i say?'

          my_class = @store.fetch(miss_key)
          my_class.should == nil
         
        end

        after(:all) do
          @store.clear
        end 
      end
    end


    describe MongoCacheStore do
      describe "initializing" do
        it "can take a Mongo::DB object" do
          db = Mongo::DB.new('mongo_store_test', Mongo::Connection.new)
          store = ActiveSupport::Cache::MongoCacheStore.new(:TTL, db: db)
        end
      end

      describe "TTL Caching" do
        it_behaves_like "a cache store" 
        before(:all) do
          db = Mongo::DB.new('mongo_cache_store_test', Mongo::Connection.new)
          @store = ActiveSupport::Cache::MongoCacheStore.new(:TTL, db: db)
        end
      end

      describe "TTL Caching Force Serialization" do
        it_behaves_like "a cache store" 
        before(:all) do
          db = Mongo::DB.new('mongo_cache_store_test', Mongo::Connection.new)
          @store = ActiveSupport::Cache::MongoCacheStore.new(:TTL, db: db, serialize: :always)
        end
      end

      describe "Standard Caching" do
        it_behaves_like "a cache store"
        before(:all) do
          db = Mongo::DB.new('mongo_cache_store_test', Mongo::Connection.new)
          @store = ActiveSupport::Cache::MongoCacheStore.new(:Standard, db: db)
        end
      end

      describe "Standard Caching Force Serialization" do
        it_behaves_like "a cache store"
        before(:all) do
          db = Mongo::DB.new('mongo_cache_store_test', Mongo::Connection.new)
          @store = ActiveSupport::Cache::MongoCacheStore.new(:Standard, db: db, serialize: :always)
        end
      end


    end
  end
end
