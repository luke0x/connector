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

class SmartGroupTest < Test::Unit::TestCase
  fixtures all_fixtures
  include CRUDTest

  crud_data 'user_id'                    => 1,
            'organization_id'            => 1,
            'smart_group_description_id' => 1,
            'name'                       => 'test smart group'

  crud_required 'user_id', 'organization_id', 'smart_group_description_id', 'name'
  
  def setup
    User.current = users(:ian)
  end
  
  def test_items
    assert_equal 1, smart_groups(:ian_files).items(nil, nil, nil).length
  end
  
  def test_tags
    # tags is serialized, I don't trust it
    assert_equal ["orange"], smart_groups(:ian_files_tagged_with_orange).tags
  end

  def test_validations
    sg = SmartGroup.create_from_search('jason')
    assert_equal 0, sg.items.length
  end
  
  def test_stays_on_current_org
    SmartGroup.find(:all).each do |sg|
      sg.items.each do |i|
        assert_equal sg.organization_id, i.organization_id
      end
    end
  end
end