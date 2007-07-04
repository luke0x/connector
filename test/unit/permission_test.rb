=begin #(fold)
Copyright 2004-2007 Joyent Inc.

Redistribution and/or modification of this code is governed
by either the GPLv2 or Joyent Commercial Software licenses.

Report issues and contribute at http://dev.joyent.com/

$Id$
=end #(end)

require File.dirname(__FILE__) + '/../test_helper'

class PermissionTest < Test::Unit::TestCase
  fixtures all_fixtures

  def setup
    # Get the ids of these before we kick scopes in
    @ian_jpg      = joyent_files(:ian_jpg).id
    @ians_dog_jpg = joyent_files(:ians_dog_jpg).id
  end
  
  def test_with_no_permissions
    # This ensures we don't mess with raw access to the models.  That is, we
    # don't want any magical scope being pushed down into the stack.  It should
    # be pretty explicit.  This test just ensures that we don't regress into
    # such an evil mechanism.
    
    assert_equal 6, JoyentFile.count
    assert_equal 6, JoyentFile.find(:all).length
  end
  
  # Permissions test set up:
  #          | ian_jpg | ians_dog_jpg 
  #  ________|_________|______________
  #  ian     |   OK    |     OK
  #  peter   |   OK    |     X
  #  stephen |   X     |     X
  #  jason   |   X     |     X
  
  def test_permissions_from_fixtures_for_ian
    Organization.current = organizations(:joyent)
    User.current         = users(:ian)
    
    assert JoyentFile.restricted_find(@ian_jpg)

    assert JoyentFile.restricted_find(@ians_dog_jpg)
  end
    
  def test_permissions_from_fixtures_for_peter
    Organization.current = organizations(:joyent)
    User.current         = users(:peter)

    assert JoyentFile.restricted_find(@ian_jpg)

    assert_raise(ActiveRecord::RecordNotFound) {
      JoyentFile.restricted_find(@ians_dog_jpg)
    }
  end

  def test_permissions_from_fixtures_for_jason
    Organization.current = organizations(:textdrive)
    User.current       = users(:jason)

    assert_raise(ActiveRecord::RecordNotFound) {
      JoyentFile.restricted_find(@ian_jpg) 
    }

    assert_raise(ActiveRecord::RecordNotFound) {
      JoyentFile.restricted_find(@ians_dog_jpg) 
    }
  end

  def test_owner_can_always_access
    Organization.current = organizations(:joyent)
    User.current         = users(:ian)

    item = Person.restricted_find(people(:stephen).id)
    assert item
    assert item.permissions.empty?
    assert_equal User.current.id, item.owner.id

    item.add_permission(users(:peter))
    assert_equal 2, item.permissions.length
    assert Person.restricted_find(:first, :conditions => ["people.id = ?", people(:stephen).id])
  end
  
  def test_restricted_count
    Organization.current = organizations(:joyent)

    User.current         = users(:ian)
    assert_equal 4, JoyentFile.restricted_count

    User.current         = users(:peter)
    assert_equal 3, JoyentFile.restricted_count
    
    User.current         = users(:jason)
    assert_equal 1, JoyentFile.restricted_count
  end

end