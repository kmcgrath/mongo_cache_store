$LOAD_PATH.unshift(File.dirname(__FILE__))
$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))
require 'mongo'
require 'active_support/cache/mongo_cache_store'
require 'rspec' 
