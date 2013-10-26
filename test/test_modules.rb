# Tests the base functionality that should be identical across all cache stores.

module EncodedKeyCacheBehavior
  if defined?(Encoding)
    Encoding.list.each do |encoding|
      define_method "test_#{encoding.name.underscore}_encoded_values" do
        key = "foo".force_encoding(encoding)
        assert @cache.write(key, 1, :raw => true)
        assert_equal 1, @cache.read(key)
        assert_equal 1, @cache.fetch(key)
        assert @cache.delete(key)
        assert_equal 2, @cache.fetch(key, :raw => true) { 2 }
        assert_equal 3, @cache.increment(key)
        assert_equal 2, @cache.decrement(key)
      end
    end

    def test_common_utf8_values
      key = "\xC3\xBCmlaut".force_encoding(Encoding::UTF_8)
      assert @cache.write(key, 1, :raw => true)
      assert_equal 1, @cache.read(key)
      assert_equal 1, @cache.fetch(key)
      assert @cache.delete(key)
      assert_equal 2, @cache.fetch(key, :raw => true) { 2 }
      assert_equal 3, @cache.increment(key)
      assert_equal 2, @cache.decrement(key)
    end

    def test_retains_encoding
      key = "\xC3\xBCmlaut".force_encoding(Encoding::UTF_8)
      assert @cache.write(key, 1, :raw => true)
      assert_equal Encoding::UTF_8, key.encoding
    end
  end
end

module CacheIncrementDecrementBehavior
  def test_increment
    @cache.write('foo', 1, :raw => true)
    assert_equal 1, @cache.read('foo').to_i
    assert_equal 2, @cache.increment('foo')
    assert_equal 2, @cache.read('foo').to_i
    assert_equal 3, @cache.increment('foo')
    assert_equal 3, @cache.read('foo').to_i
  end

  def test_decrement
    @cache.write('foo', 3, :raw => true)
    assert_equal 3, @cache.read('foo').to_i
    assert_equal 2, @cache.decrement('foo')
    assert_equal 2, @cache.read('foo').to_i
    assert_equal 1, @cache.decrement('foo')
    assert_equal 1, @cache.read('foo').to_i
  end
end

module LocalCacheBehavior
  def test_local_writes_are_persistent_on_the_remote_cache
    retval = @cache.with_local_cache do
      @cache.write('foo', 'bar')
    end
    assert retval
    assert_equal 'bar', @cache.read('foo')
  end

  def test_clear_also_clears_local_cache
    @cache.with_local_cache do
      @cache.write('foo', 'bar')
      @cache.clear
      assert_nil @cache.read('foo')
    end

    assert_nil @cache.read('foo')
  end

  def test_local_cache_of_write
    @cache.with_local_cache do
      @cache.write('foo', 'bar')
      @peek.delete('foo')
      assert_equal 'bar', @cache.read('foo')
    end
  end

  def test_local_cache_of_read
    @cache.write('foo', 'bar')
    @cache.with_local_cache do
      assert_equal 'bar', @cache.read('foo')
    end
  end

  def test_local_cache_of_write_nil
    @cache.with_local_cache do
      assert @cache.write('foo', nil)
      assert_nil @cache.read('foo')
      @peek.write('foo', 'bar')
      assert_nil @cache.read('foo')
    end
  end

  def test_local_cache_of_delete
    @cache.with_local_cache do
      @cache.write('foo', 'bar')
      @cache.delete('foo')
      assert_nil @cache.read('foo')
    end
  end

  def test_local_cache_of_exist
    @cache.with_local_cache do
      @cache.write('foo', 'bar')
      @peek.delete('foo')
      assert @cache.exist?('foo')
    end
  end

  def test_local_cache_of_increment
    @cache.with_local_cache do
      @cache.write('foo', 1, :raw => true)
      @peek.write('foo', 2, :raw => true)
      @cache.increment('foo')
      assert_equal 3, @cache.read('foo')
    end
  end

  def test_local_cache_of_decrement
    @cache.with_local_cache do
      @cache.write('foo', 1, :raw => true)
      @peek.write('foo', 3, :raw => true)
      @cache.decrement('foo')
      assert_equal 2, @cache.read('foo')
    end
  end

  def test_middleware
    app = lambda { |env|
      result = @cache.write('foo', 'bar')
      assert_equal 'bar', @cache.read('foo') # make sure 'foo' was written
      assert result
    }
    app = @cache.middleware.new(app)
    app.call({})
  end
end

module CacheStoreBehavior
  def test_should_read_and_write_strings
    assert @cache.write('foo', 'bar')
    assert_equal 'bar', @cache.read('foo')
  end

  def test_should_overwrite
    @cache.write('foo', 'bar')
    @cache.write('foo', 'baz')
    assert_equal 'baz', @cache.read('foo')
  end

  def test_fetch_without_cache_miss
    @cache.write('foo', 'bar')
    @cache.expects(:write).never
    assert_equal 'bar', @cache.fetch('foo') { 'baz' }
  end

  def test_fetch_with_cache_miss
    @cache.expects(:write).with('foo', 'baz', @cache.options)
    assert_equal 'baz', @cache.fetch('foo') { 'baz' }
  end

  def test_fetch_with_forced_cache_miss
    @cache.write('foo', 'bar')
    @cache.expects(:read).never
    @cache.expects(:write).with('foo', 'bar', @cache.options.merge(:force => true))
    @cache.fetch('foo', :force => true) { 'bar' }
  end

  def test_fetch_with_cached_nil
    @cache.write('foo', nil)
    #@cache.expects(:write).never
    assert_nil @cache.fetch('foo') { 'baz' }
  end

  def test_should_read_and_write_hash
    assert @cache.write('foo', {:a => "b"})
    assert_equal({:a => "b"}, @cache.read('foo'))
  end

  def test_should_read_and_write_integer
    assert @cache.write('foo', 1)
    assert_equal 1, @cache.read('foo')
  end

  def test_should_read_and_write_nil
    assert @cache.write('foo', nil)
    assert_equal nil, @cache.read('foo')
  end

  def test_should_read_and_write_false
    assert @cache.write('foo', false)
    assert_equal false, @cache.read('foo')
  end

  if ActiveSupport::VERSION::MAJOR == 3
    def test_should_read_cached_numeric_from_previous_rails_versions
      @old_cache = ActiveSupport::Cache::Entry.create( 1, Time.now )
      assert_equal( 1, @old_cache.value )
    end

    def test_should_read_cached_hash_from_previous_rails_versions
      @old_cache = ActiveSupport::Cache::Entry.create( {}, Time.now )
      assert_equal( {}, @old_cache.value )
    end

    def test_should_read_cached_string_from_previous_rails_versions
      @old_cache = ActiveSupport::Cache::Entry.create( 'string', Time.now )
      assert_equal( 'string', @old_cache.value )
    end
  end

  def test_read_multi
    @cache.write('foo', 'bar')
    @cache.write('fu', 'baz')
    @cache.write('fud', 'biz')
    assert_equal({"foo" => "bar", "fu" => "baz"}, @cache.read_multi('foo', 'fu'))
  end

  def test_read_multi_with_expires
    @cache.write('foo', 'bar', :expires_in => 0.001)
    @cache.write('fu', 'baz')
    @cache.write('fud', 'biz')
    sleep(0.002)
    assert_equal({"fu" => "baz"}, @cache.read_multi('foo', 'fu'))
  end

  if ActiveSupport::VERSION::MAJOR == 3
    def test_read_and_write_compressed_small_data
      @cache.write('foo', 'bar', :compress => true)
      raw_value = @cache.send(:read_entry, 'foo', {}).raw_value
      assert_equal 'bar', @cache.read('foo')
      assert_equal 'bar', Marshal.load(raw_value)
    end

    def test_read_and_write_compressed_large_data
      @cache.write('foo', 'bar', :compress => true, :compress_threshold => 2)
      raw_value = @cache.send(:read_entry, 'foo', {}).raw_value
      assert_equal 'bar', @cache.read('foo')
      assert_equal 'bar', Marshal.load(Zlib::Inflate.inflate(raw_value))
    end
  end

  def test_read_and_write_compressed_nil
    @cache.write('foo', nil, :compress => true)
    assert_nil @cache.read('foo')
  end

  def test_cache_key
    obj = Object.new
    def obj.cache_key
      :foo
    end
    @cache.write(obj, "bar")
    assert_equal "bar", @cache.read("foo")
  end

  def test_param_as_cache_key
    obj = Object.new
    def obj.to_param
      "foo"
    end
    @cache.write(obj, "bar")
    assert_equal "bar", @cache.read("foo")
  end

  def test_array_as_cache_key
    @cache.write([:fu, "foo"], "bar")
    assert_equal "bar", @cache.read("fu/foo")
  end

  def test_hash_as_cache_key
    @cache.write({:foo => 1, :fu => 2}, "bar")
    assert_equal "bar", @cache.read({:foo => 1, :fu => 2})
  end

  def test_keys_are_case_sensitive
    @cache.write("foo", "bar")
    assert_nil @cache.read("FOO")
  end

  def test_exist
    @cache.write('foo', 'bar')
    assert @cache.exist?('foo')
    assert !@cache.exist?('bar')
  end

  def test_nil_exist
    @cache.write('foo', nil)
    assert @cache.exist?('foo')
  end

  def test_delete
    @cache.write('foo', 'bar')
    assert @cache.exist?('foo')
    assert @cache.delete('foo')
    assert !@cache.exist?('foo')
  end

  def test_read_should_return_a_different_object_id_each_time_it_is_called
    @cache.write('foo', 'bar')
    assert_not_equal @cache.read('foo').object_id, @cache.read('foo').object_id
    value = @cache.read('foo')
    value << 'bingo'
    assert_not_equal value, @cache.read('foo')
  end

  def test_original_store_objects_should_not_be_immutable
    bar = 'bar'
    @cache.write('foo', bar)
    assert_nothing_raised { bar.gsub!(/.*/, 'baz') }
  end

  def test_expires_in
    time = Time.local(2008, 4, 24)
    Time.stubs(:now).returns(time)

    @cache.write('foo', 'bar')
    assert_equal 'bar', @cache.read('foo')

    Time.stubs(:now).returns(time + 30)
    assert_equal 'bar', @cache.read('foo')

    Time.stubs(:now).returns(time + 61)
    assert_nil @cache.read('foo')
  end

  #def test_race_condition_protection
  #  time = Time.now
  #  @cache.write('foo', 'bar', :expires_in => 60)
  #  Time.stubs(:now).returns(time + 61)
  #  result = @cache.fetch('foo', :race_condition_ttl => 10) do
  #    assert_equal 'bar', @cache.read('foo')
  #    "baz"
  #  end
  #  assert_equal "baz", result
  #end

  def test_race_condition_protection_is_limited
    time = Time.now
    @cache.write('foo', 'bar', :expires_in => 60)
    Time.stubs(:now).returns(time + 71)
    result = @cache.fetch('foo', :race_condition_ttl => 10) do
      assert_equal nil, @cache.read('foo')
      "baz"
    end
    assert_equal "baz", result
  end

  #def test_race_condition_protection_is_safe
  #  time = Time.now
  #  @cache.write('foo', 'bar', :expires_in => 60)
  #  Time.stubs(:now).returns(time + 61)
  #  begin
  #    @cache.fetch('foo', :race_condition_ttl => 10) do
  #      assert_equal 'bar', @cache.read('foo')
  #      raise ArgumentError.new
  #    end
  #  rescue ArgumentError
  #  end
  #  assert_equal "bar", @cache.read('foo')
  #  Time.stubs(:now).returns(time + 71)
  #  assert_nil @cache.read('foo')
  #end

  def test_crazy_key_characters
    crazy_key = "#/:*(<+=> )&$%@?;'\"\'`~-"
    assert @cache.write(crazy_key, 1, :raw => true)
    assert_equal 1, @cache.read(crazy_key)
    assert_equal 1, @cache.fetch(crazy_key)
    assert @cache.delete(crazy_key)
    assert_equal 2, @cache.fetch(crazy_key, :raw => true) { 2 }
    assert_equal 3, @cache.increment(crazy_key)
    assert_equal 2, @cache.decrement(crazy_key)
  end

  def test_really_long_keys
    key = ""
    900.times{key << "x"}
    assert @cache.write(key, "bar")
    assert_equal "bar", @cache.read(key)
    assert_equal "bar", @cache.fetch(key)
    assert_nil @cache.read("#{key}x")
    assert_equal({key => "bar"}, @cache.read_multi(key))
    assert @cache.delete(key)
  end
end

module CacheDeleteMatchedBehavior
  def test_delete_matched
    @cache.write("foo", "bar")
    @cache.write("fu", "baz")
    @cache.write("foo/bar", "baz")
    @cache.write("fu/baz", "bar")
    @cache.delete_matched(/oo/)
    assert !@cache.exist?("foo")
    assert @cache.exist?("fu")
    assert !@cache.exist?("foo/bar")
    assert @cache.exist?("fu/baz")
  end
end

module CacheIncrementDecrementBehavior
  def test_increment
    @cache.write('foo', 1, :raw => true)
    assert_equal 1, @cache.read('foo').to_i
    assert_equal 2, @cache.increment('foo')
    assert_equal 2, @cache.read('foo').to_i
    assert_equal 3, @cache.increment('foo')
    assert_equal 3, @cache.read('foo').to_i
    assert_nil @cache.increment('bar')
  end

  def test_decrement
    @cache.write('foo', 3, :raw => true)
    assert_equal 3, @cache.read('foo').to_i
    assert_equal 2, @cache.decrement('foo')
    assert_equal 2, @cache.read('foo').to_i
    assert_equal 1, @cache.decrement('foo')
    assert_equal 1, @cache.read('foo').to_i
    assert_nil @cache.decrement('bar')
  end
end

