require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper')


class MongoCacheStoreTestSaveClass

  attr_reader :set_me
  def initialize(set_me)
    @set_me = set_me
  end

end


module ActiveSupport 
  module Cache
    describe MongoCacheStore do
      describe "initializing" do
        it "can take a Mongo::Collection object" do
          db = Mongo::DB.new('mongo_store_test', Mongo::Connection.new)
          store = ActiveSupport::Cache::MongoCacheStore.new(:TTL, db: db)
        end
        
      end

      describe "TTL caching" do
        before(:all) do
          db = Mongo::DB.new('mongo_ttl_store_test', Mongo::Connection.new)
          @store = ActiveSupport::Cache::MongoCacheStore.new(:TTL, db: db)
        end
    
        it "can write values" do
          @store.write('forever!', 'I live forever!')
          @store.fetch('forever!').should == "I live forever!"
        end

        it "can expire" do
          @store.fetch 'fnord', expires_in: 30.seconds do 
            "I am vaguely disturbed."
          end

          sleep 65

          response = @store.fetch 'fnord'
          response.should == nil
        end

        it "can cache objects" do
          @store.fetch 'my_class', expires_in: 30.seconds do
            MongoCacheStoreTestSaveClass.new('what did i say?')
          end

          my_class = @store.fetch 'my_class', expires_in: 30.seconds
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

      end

    end
  end
end
