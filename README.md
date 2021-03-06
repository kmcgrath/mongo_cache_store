# MongoCacheStore

A MongoDB cache store for ActiveSupport

## Description

MongoCacheStore uses pluggable backends to expose MongoDB 
as a cache store to ActiveSupport applications.  Each backend 
allows the application to customize how the cache operates.  
Support is available for standard, capped and TTL collections.

## Upgrade Note

To accommodate ActiveSupport 4 underlying storage routines had
to change.  After upgrading to 0.3.0, any cached entries from 0.2.x
will be considered a miss and will be overridden with a corresponding
write action or expire naturally.

MongoCacheStore::DATA\_STORE\_VERSION determines whether a cached entry
is compatible with the current version of the gem.


## Initialize the cache

### Usage


    config.cache_store = :mongo_cache_store, :TTL, :db => Mongo::DB.new('db_name',Mongo::Connection.new)
    config.cache_store = :mongo_cache_store, :Standard, :db_name => 'db_name', :connection => Mongo::Connection.new, :serialize => :on_fail


### Attributes  
 
#### backend

Symbol representing the backend the cache should use 

  * *:TTL* - ActiveSupport::Cache::MongoCacheStore::Backend::TTL
  * *:Standard* - ActiveSupport::Cache::MongoCacheStore::Backend::Standard
  * *:MultiTTL* - ActiveSupport::Cache::MongoCacheStore::Backend::MultiTTL
  * *:Capped* - ActiveSupport::Cache::MongoCacheStore::Backend::Capped

#### options

Options for ActiveSupport::Cache and the backend] 
    
Core options are listed here.  See each backend for a list of additional optons. 

  * *:db* - A Mongo::DB instance.
  * *:db_name* - Name of database to create if no 'db' is given.
  * *:connection* - A Mongo::Connection instance. Only used if no 'db' is given.
  * *:collection_opts*
    > Hash of options passed directly to MongoDB::Collection.
       
    > Useful for write conditions and read preferences

  * *:serialize* - *:always* | :on_fail | :never
    * *:always* - (default) - Serialize all entries
      > *NOTE* Without serialization class structures and instances that cannot 
        be converted to a native MongoDB type will not be stored.  Also, 
        without serialization MongoDB converts all symbols to strings.  
            
      > Therefore a hash with symbols as keys will have strings as keys when read.
 
    * *:on_fail* - Serialize if native format fails
      > Try to save the entry in a native MongoDB format.  If that fails, 
        then serialize the entry. 
    * *:never* - Never serialize
      > Only save the entry if it can be saved natively by MongoDB.


## Increment / Decrement

Increment and decrement values must be an Integer.  In the ActiveSupport test
suite strings and integers are used interchangeably.  This cache store however
uses MongoDB's $inc operator which must, be an integer.  


## Keys can be a Hash

The following test from ActiveSupport fails with MongoCacheStore:

    def test_hash_as_cache_key
      @cache.write({:foo => 1, :fu => 2}, "bar")
      assert_equal "bar", @cache.read("foo=1/fu=2")
    end

This is because a key can be a true Hash.  It will not be converted to a string.


## Backends

### TTL


TTL backend for MongoCacheStore

#### Description
  
Entries are kept in a namespaced TTL collection that will 
automatically flush any entries as they pass their expiration 
time. This keeps the size of the cache in check over time. 

<b>Requires MongoDB 2.2 or higher</b>

#### Additional Options

No additional options at this time

***
### Standard

Standard backend for MongoCacheStore
 
#### Description

Entries are kept in a namespaced MongoDB collection. In a standard 
collection entries are only flushed from the collection with an 
explicit delete call or if auto_flush is enabled.  If auto_flush is 
enabled the cache will flush all expired entries when auto\_flush\_threshold 
is reached.  The threshold is based on a set number of cache instance writes. 

#### Additional Options  
 
The following options can be added to a MongoCacheStore constructor
 
To see a list of core options see MongoCacheStore

  * *:auto_flush* - *true* | false
    > Default: true
        
    > If auto_flush is enabled the cache will flush all 
      expired entries when auto\_flush\_threshold
      is reached.

  * *:auto_flush_threshold* - *10_000* 
    > Default: 10_000

    > A number representing the number of writes the when the cache 
      should preform before flushing expired entries.

***
### MultiTTL 


MultiTTL backend for MongoCacheStore
 
#### Description

Entries are stored in multiple namespaced TTL collections. 
A namespaced TTL collection is created for each unique expiration time.  
For example all entries with an expiration time of 300 seconds will be 
kept in the same collection while entries with a 900 second expiration 
time will be kept in another.  This requires the use of a *key index* 
collection that keeps track of which TTL collection a entry resides in. 

##### Downsides
* Cache set operations require 2 MongoDB write calls.  
  One for the key index, one for the TTL collection. 
  (unless *use_index* is false, see below)
* Cache read operations will require 1 or 2 MongoDB calls 
  depending on whether the 'expires_in' option is set for the read.

##### Benefits (future)
* Ability to flush cache based on expire time (TODO)


#### Additional Options  
  
The following options can be added to a MongoCacheStore constructor

To see a list of core options see MongoCacheStore

  * *:use_index* - *true* | false
  > Default: true

  > This should only be set to *false* if all fetch and/or read 
    operations are passed the *:expires_in* option.  If so, this 
    will eliminate the need for the key index collection and only 
    one write and one read operation is necessary. 

***
### Capped

 
*Experimental*

Capped backend for MongoCacheStore

### Description
*Experimental* do not use... yet.
 
This should only be used if limiting the size of the cache 
is of great concern.  Entries are flushed from the cache on 
a FIFO basis, regardless of the entries expiration time.  
Delete operations set an entry to expired, but it will not 
be flushed until it is automatically removed by MongoDB.
  
#### Options

TODO
 
## Build Health
[![Build Status - Master](https://travis-ci.org/kmcgrath/mongo_cache_store.png?branch=master)](https://travis-ci.org/kmcgrath/mongo_cache_store)
[![Code Climate](https://codeclimate.com/github/kmcgrath/mongo_cache_store.png)](https://codeclimate.com/github/kmcgrath/mongo_cache_store)
[![Dependency Status](https://gemnasium.com/kmcgrath/mongo_cache_store.png)](https://gemnasium.com/kmcgrath/mongo_cache_store)

Travis is used to build and test MongoCacheStore against:
* 2.0.0
* 1.9.3
* 1.9.2
* 1.8.7
* jruby-18mode
* jruby-19mode
* rbx-19mode 
* ruby-head
* jruby-head
* ree

