# MongoCacheStore

A MongoDB cache store for ActiveSupport 3

## Description

MongoCacheStore uses pluggable backends to expose MongoDB as a cache store to ActiveSupport applications.  Each backend allows the application to customize how the cache operates.  Support is available for standard, capped and TTL collections.

*WARNING* This gem is in the early stages of development and should be treated as such.  Checking the version of the gem will help with what could be many changes to the backends, options, etc...

While in beta, the major version will always be 0.  The minor version will be increased for anything that breaks the current API.  The patch version will be increased for all changes within a minor revision that add to or fix the currenr release without changing the how the gem is configured or used. 


## Backends

A Backend controls how MongoDB collections are used and manipulated as a cache store.

MongoCacheStore ships with 4 backends, TTL, Capped, Standard and MultiTTL.

The major difference between each backend involves how entries are flushed.  The core driver will always respect ActiveSupport's *:expires_in* parameter for hits and misses whether the entry has actually been flushed from the backend or not. 

#### Core Options
* db: A Mongo::DB instance
* serialize: (*:always*, :on\_fail, :never)
  * :always (default) - Serialize all entries
  * :on\_fail - Try to save the entry in a native MongoDB format.  If that fails, then serialize the entry. 
  * :never - only save the entry if it can be saved natively by MongoDB.
  * *NOTE:* Without serialization class structures and instances that cannot be converted to a native MongoDB type will not be stored.  Also, without serialization MongoDB converts all symbols to strings.  Therefore a hash with symbols as keys will have strings as keys when read.


### TTL
Entries are kept in a namespaced TTL collection that will automatically flush any entries as they pass their expiration time.  This keeps the size of the cache in check over time. 
  
* *Requires MongoDB 2.0 or higher*

#### Options
No Extra options

### Standard
Entreis are kept in a namespaced MongoDB collection. In a standard collection entries are only flushed from the collection with an explicit delete call or if auto_flush is enabled.  If auto_flush is enabled the cache will flush all expired entries when auto\_flush\_threshold is reached.  The threshold is based on a set number of cache instance writes. 

#### Options
* auto_flush: (*true*|false)
* auto\_flush\_threshold: *10_000*
 

### Capped (TODO)
This should only be used if limiting the size of the cache is the greatest concern.  Entries are flushed from the cache on a FIFO basis, regardless of the entries expiration time.  Delete operations set an entry to expired, but it will not be flushed until it is automatically removed by MongoDB.


### MultiTTL
Entries are stored in multiple namespaced TTL collections. A namespaced TTL collection is created for each unique expiration time.  For example all entries with an expiration time of 300 seconds will be kept in the same collection while entries with a 900 second expiration time will be kept in another.  This requires the use of a *key index* collection that keeps track of which TTL collection a entry resides in. 

#### Downsides
  * Cache set operations require 2 MongoDB write calls.  One for the key index, one for the TTL collection. (unless *use_index* is false, see below)
  * Cache read operations will require 1 or 2 MongoDB calls depending on whether the 'expires_in' option is set for the read.

#### Benefits
  * Ability to flush cache based on expire time (TODO)

#### Options
use\_index: (*true*, false)
  * This should only be set to *false* if all fetch and/or read operations are passed the *:expires_in* option.  If so, this will eliminate the need for the key index collection and only one write and one read operation is necessary. 



## Installation

Add this line to your application's Gemfile:

    gem 'mongo_cache_store'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install mongo_cache_store

## Usage



## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
