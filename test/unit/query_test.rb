=begin #(fold)
Copyright 2004-2007 Joyent Inc.

Redistribution and/or modification of this code is governed
by either the GPLv2 or Joyent Commercial Software licenses.

Report issues and contribute at http://dev.joyent.com/

$Id$
=end #(end)

require File.dirname(__FILE__) + '/../test_helper'

class QueryTest < Test::Unit::TestCase
  fixtures all_fixtures
  
  def test_smart_group_conversion
    q = convert_smart_group(:ian_everything_from_peter)
    h = {"owner_name"=>"peter"}
    assert_equal h, q.attributes
    assert_equal '', q.search_text
    assert_nil   q.tags
  end
  
  def test_smart_group_conversion_with_body_attribute
    q = convert_smart_group(:ian_people_body_foo)
    h = {"item_type"=>"Person"}
    assert_equal h, q.attributes
    assert_equal 'foo', q.search_text
    assert_nil q.tags
  end
  
  def test_smart_group_conversion_with_tags
    q = convert_smart_group(:peter_people_tagged_foo)
    h = {"item_type"=>"Person"}
    assert_equal ['foo'], q.tags.sort
    assert_equal h, q.attributes
    assert_equal '', q.search_text
  end
  
  def test_text_with_no_item_type
    q = Query.query_for("asdf")
    assert_equal [], q.tags
    assert_equal({}, q.attributes)
    assert_equal 'asdf', q.search_text
  end

  def test_to_s
    q = Query.query_for("asdf")
    assert q.to_s =~ /Query search_text/
  end
  
  def convert_smart_group(fixture_name)
    Query.from_smart_group(smart_groups(fixture_name))
  end
  
end