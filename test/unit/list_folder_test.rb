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

class ListFolderTest < Test::Unit::TestCase
  fixtures all_fixtures
  include CRUDTest

  crud_data 'user_id'         => 1,
            'organization_id' => 1,
            'parent_id'       => 1,
            'name'            => 'Got Me Some Lists'
            
  crud_required 'user_id', 'organization_id', 'parent_id', 'name'
  
  def setup
    User.current = users(:ian)
  end

  # class
  
  def test_self_class_humanize
    assert_equal list_folders(:ian_lists).class.class_humanize, 'Folder'
  end

  # instance

  def test_class_humanize
    assert_equal list_folders(:ian_lists).class_humanize, 'Folder'
  end
  
  def test_descendent?
  end
  
  def test_rename!
    l = list_folders(:ian_lists)
    n = l.name
    l.rename!('yo a new name') # can't rename 'root' list
    assert_equal l.name, n

    l = list_folders(:ian_silly_lists)
    n = l.name
    l.rename!('') # can't rename to blank
    assert l.errors.length > 0
    assert_equal l.reload.name, n

    l.rename!('yo a new name') # finally should work
    assert_not_equal l.name, n
  end
  
  def test_reparent!
  end
  
  def test_validate
  end

end