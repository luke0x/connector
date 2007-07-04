=begin #(fold)
Copyright 2004-2007 Joyent Inc.

Redistribution and/or modification of this code is governed
by either the GPLv2 or Joyent Commercial Software licenses.

Report issues and contribute at http://dev.joyent.com/

$Id$
=end #(end)

require File.dirname(__FILE__) + '/../test_helper'

class BookmarkFolderTest < Test::Unit::TestCase
  fixtures all_fixtures
  include CRUDTest

  crud_data 'user_id'         => 1,
            'organization_id' => 1

  crud_required 'user_id', 'organization_id'

  def test_crud
    User.current = users(:ian)
    Organization.current = User.current.organization
    run_crud_tests
  end

  def test_cascade_permissions
    User.current = users(:ian)
    Organization.current = User.current.organization

    assert bookmark_folders(:ian_bookmark_folder).permissions.empty?
    assert bookmark_folders(:ian_bookmark_folder).bookmarks.first.permissions.empty?
    
    bookmark_folders(:ian_bookmark_folder).restrict_to!([users(:ian)])
    assert_equal 1, bookmark_folders(:ian_bookmark_folder).permissions.length
    assert_equal users(:ian), bookmark_folders(:ian_bookmark_folder).permissions.first.user
    assert_equal 1, bookmark_folders(:ian_bookmark_folder).bookmarks.first.permissions.length
    assert_equal users(:ian), bookmark_folders(:ian_bookmark_folder).bookmarks.first.permissions.first.user
  end

end