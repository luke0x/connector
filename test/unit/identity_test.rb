=begin #(fold)
Copyright 2004-2007 Joyent Inc.

Redistribution and/or modification of this code is governed
by either the GPLv2 or Joyent Commercial Software licenses.

Report issues and contribute at http://dev.joyent.com/

$Id$
=end #(end)

require File.dirname(__FILE__) + '/../test_helper'

class IdentityTest < Test::Unit::TestCase
  fixtures all_fixtures
  
  include CRUDTest
  crud_data 'name' => ''
  
  def test_users
    assert_equal 4, identities(:ian_peter_jason).users.length
  end
end
