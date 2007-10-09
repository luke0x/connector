=begin #(fold)
++
Copyright 2004-2007 Joyent Inc.

Redistribution and/or modification of this code is 
governed by the GPLv2.

Report issues and contribute at http://dev.joyent.com/

$Id$
--
=end #(end)

require File.dirname(__FILE__) + '/../test_helper'

class SmartGroupDescriptionTest < Test::Unit::TestCase
  fixtures :smart_group_descriptions

  def test_validations
    s = SmartGroupDescription.create()
    assert_equal 1, s.errors.length
  end
end