=begin #(fold)
++
Copyright 2004-2007 Joyent Inc.

Redistribution and/or modification of this code is 
governed by the GPLv2.

Report issues and contribute at http://dev.joyent.com/

$Id$
--
=end #(end)

require 'test/unit'
require 'ostruct'
require File.dirname(__FILE__) + '/../init'

class Foo
  def foo
    subclass_responsibility
  end
  
  def bar
    should_not_implement
  end
end

class JoyentRubyTest < Test::Unit::TestCase
  def test_nil_id
    assert_raise(ArgumentError) {
      nil.id
    }
  end
  
  def test_object_subclass_responsibility
    f = Foo.new
    assert_raise(RuntimeError) {
      f.foo
    }
  end
  
  def test_object_should_not_implement
    f = Foo.new
    assert_raise(RuntimeError) {
      f.bar
    }
  end
  
  def test_numeric_clamp
    assert_equal 5,   4.clamp(5,10)
    assert_equal 5,   5.clamp(5,10)
    assert_equal 7,   7.clamp(5,10)
    assert_equal 10, 10.clamp(5,10)
    assert_equal 10, 11.clamp(5,10)
  end
  
  def test_hash_contains_hash_with_value
    x = {:bling => {:foo => 'bar'}}
    assert(x.contains_hash_with_value?('bar'))
    assert(!x.contains_hash_with_value?('baz'))
  end
  
  def test_hash_compact
    x = {:foo => 'bar', :baz => nil}
    assert_equal({:foo => 'bar'}, x.compact)
  end
  
  def test_array_index_by
    x = [1]
    assert_equal({'1' => 1}, x.index_by {|a| a.to_s})
  end
  
  def test_array_group_by
    x = [1, 1, 2]
    
    assert_equal({"1"=>[1, 1], "2"=>[2]}, x.group_by {|a| a.to_s })
  end
  
  def test_array_hash_collect
    x = [1, 2]
    y = x.hash_collect { |x| [x, x * 2]}
    assert_equal({1=>2, 2=>4}, y)
  end
  
  def test_contains_hash_with_value
    x = [{:foo => 'bar'}]
    
    assert x.contains_hash_with_value?('bar')
    assert !x.contains_hash_with_value?('baz')
  end
  
  def test_index_of_object_with_matching_property
    fred = OpenStruct.new :name => 'fred'
    bob  = OpenStruct.new :name => 'bob'
    
    x = [fred, bob]
    
    assert_equal 0, x.index_of_object_with_matching_property('name', 'fred')
    assert_equal 1, x.index_of_object_with_matching_property('name', 'bob')
    assert_nil x.index_of_object_with_matching_property('name', 'joe')
  end
  
  def test_array_sort_in_parallel
    assert_raise(RuntimeError) {
      Array.sort_in_parallel [1], [1, 2]
    }
    
    x = [4, 3, 8]
    y = [2, 1, 3]
    a, b = Array.sort_in_parallel x, y
    assert_equal [3, 4, 8], a
    assert_equal [1, 2, 3], b
  end
  
  def test_midnight_works
    assert !Time.local(2005, 01, 02, 22, 23, 34).midnight?
    assert Time.local(2005,01,01, 0,0,0).midnight?
  end
end
