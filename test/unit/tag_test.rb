=begin #(fold)
Copyright 2004-2007 Joyent Inc.

Redistribution and/or modification of this code is governed
by either the GPLv2 or Joyent Commercial Software licenses.

Report issues and contribute at http://dev.joyent.com/

$Id$
=end #(end)

require File.dirname(__FILE__) + '/../test_helper'

class TagTest < Test::Unit::TestCase
  fixtures all_fixtures
  include CRUDTest
  
  crud_data 'name'            => 'Dogs',
            'organization_id' => 1

  crud_required 'name', 'organization_id'
  
  def test_unique_name_per_organization
    assert_create
    assert_no_create
    
    @test_data['organization_id'] = 2
    assert_create
  end
  
  def test_items
    assert_equal 5, tags(:orange).items.map(&:id).length
  end   
  
  def test_restricted_items
    User.current = users(:peter)
    Organization.current = User.current.organization

    assert_equal 5, tags(:orange).items.size
    assert_equal 3, tags(:orange).restricted_items.size 
    
    tags(:orange).restricted_items.first.remove_permission(users(:peter))

    # can't remove permissions from yourself
    assert_equal 5, tags(:orange).items.size
    assert_equal 3, tags(:orange).restricted_items.size
  end
end