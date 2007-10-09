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

class LoginTokenTest < Test::Unit::TestCase
  fixtures all_fixtures

  def test_creating_sets_value
    assert users(:ian).remember_login.value
  end
  
  def test_find_by_value_finds_current_values
    assert_equal users(:jason), LoginToken.find_by_value("imnew").user
  end
  
  def test_remembering_and_recalling
    tok = users(:jason).remember_login.value
    assert_equal users(:jason), LoginToken.find_by_value(tok).user
  end
end