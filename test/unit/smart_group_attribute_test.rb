=begin #(fold)
Copyright 2004-2007 Joyent Inc.

Redistribution and/or modification of this code is governed
by either the GPLv2 or Joyent Commercial Software licenses.

Report issues and contribute at http://dev.joyent.com/

$Id$
=end #(end)

require File.dirname(__FILE__) + '/../test_helper'

class SmartGroupAttributeTest < Test::Unit::TestCase
  fixtures all_fixtures

  def test_attribute_name
    assert_equal "filename", smart_group_attributes(:first_for_fnlfobi).attribute_name
  end
  
  def test_validations
    s = SmartGroupAttribute.create()
    assert_equal 3, s.errors.length
  end
end