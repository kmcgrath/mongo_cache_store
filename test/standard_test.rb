require 'abstract_unit'
require 'mongo'
require 'active_support/test_case'
require 'active_support/cache'
require 'test_modules'



class MongoCacheStoreStandardTest < ActiveSupport::TestCase
  def setup
    @cache = ActiveSupport::Cache.lookup_store(
      :mongo_cache_store, :Standard, 
      :db => Mongo::DB.new('db_name',Mongo::Connection.new),
      :expires_in => 60
    )
    @cache.clear
  end

  include CacheStoreBehavior
  # include LocalCacheBehavior
  include CacheIncrementDecrementBehavior
  # include EncodedKeyCacheBehavior

end
