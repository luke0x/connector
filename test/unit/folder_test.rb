=begin #(fold)
Copyright 2004-2007 Joyent Inc.

Redistribution and/or modification of this code is governed
by either the GPLv2 or Joyent Commercial Software licenses.

Report issues and contribute at http://dev.joyent.com/

$Id$
=end #(end)

require File.dirname(__FILE__) + '/../test_helper'

class FolderTest < Test::Unit::TestCase
  fixtures all_fixtures
  include CRUDTest

  crud_data 'user_id'         => 1,
            'parent_id'       => nil,
            'name'            => 'Photos',
            'organization_id' => 1
            
  crud_required 'user_id', 'name', 'organization_id'
  
  def test_pathname
    assert_equal 'Pictures/Vacation', folders(:ian_pictures_vacation).pathname
  end
  
  def test_file_system_directory_created_and_destroyed_for_folder
    @test_data['name'] = 'UnitTest'
    folder = assert_create
    assert MockFS.file.exist?(folder.path_on_disk)
    
    folder.destroy
    assert !MockFS.file.exist?(folder.path_on_disk)
  end
  
  def test_rename
    f = folders(:ian_pictures_vacation)
    old_path = f.path_on_disk
    assert MockFS.file.exist?(old_path)

    f.rename!("Okay")
    f.reload
    
    assert_equal "Okay", f.name
    assert MockFS.file.exist?(f.path_on_disk)
    assert !MockFS.file.exist?(old_path)
    
    f.rename!("Vacation")
  end
  
  def test_reparent!
    f = folders(:ian_pictures_vacation)
    p = folders(:ian_attachments)
    
    # This looks cracked out, and it is,  but one day I'll tell you a story about the core team member 
    # who forgot about ActiveRecord::Associations::BelongsToAssociation
    
    op = Folder.find(f.parent.id)
    old_path = f.path_on_disk
    
    f.reparent!(p)
    
    f.reload
    assert MockFS.file.exist?(f.path_on_disk)
    assert !MockFS.file.exist?(old_path)
    assert_equal p, f.parent 
    
    
    f.reparent!(op)
  end
  
  def test_restrict_to_changes_perms
    f = folders(:ian_pictures)
    f.restrict_to!([users(:peter), users(:ian)])
    
    f.reload
    
    assert_equal ["ian", "peter"], f.permissions.map(&:user).map(&:username).sort
  end

  def test_securable_public
    f = folders(:ian_pictures)
    Organization.current = f.organization
    User.current = f.owner
    assert f.permissions.empty?
    assert f.public?
    
    f.organization.users.each do |u|
      f.permissions.create(:user_id => u.id) # don't use restrict_to! here
    end
    assert_equal f.permissions.length, f.organization.users.length
    assert f.public?
  end
  
  def test_securable_restricted
    f = folders(:ian_pictures)
    Organization.current = f.organization
    User.current = f.owner
    assert f.permissions.empty?
    assert ! f.restricted?
    
    f.organization.users.each do |u|
      f.permissions.create(:user_id => u.id) # don't use restrict_to! here
    end
    assert_equal f.permissions.length, f.organization.users.length
    assert ! f.restricted?
  end
  
  def test_ensure_public_is_empty
    f = folders(:ian_pictures)
    Organization.current = f.organization
    User.current = f.owner
    assert_equal 3, Organization.current.users_and_admins.length
    assert f.public?
    
    f.add_permission(f.owner)
    assert_equal 1, f.permissions.length
    assert ! f.public?
    
    f.add_permission(users(:peter))
    assert_equal 2, f.permissions.length
    assert ! f.public?

    f.add_permission(users(:bernard))
    assert_equal 0, f.permissions.length # should reset to 0
    assert f.public?
  end
  
  def test_restrict_to_changes_perms_for_files
    f = folders(:ian_pictures_vacation)
    f.restrict_to!([users(:peter), users(:ian)])
  
    f.reload
  
    f.joyent_files.each do |jf|
      assert_equal ["ian", "peter"], jf.permissions.map(&:user).map(&:username).sort
    end
  end
  
  def test_restrict_to_changes_perms_for_children
    f = folders(:ian_pictures)
    f.restrict_to!([users(:peter), users(:ian)])
  
    f.reload
  
    f.children.each do |c|
      assert_equal ["ian", "peter"], c.permissions.map(&:user).map(&:username).sort
    end
  end

  def test_restriced_find_doesnt_cross_orgs
    User.current = users(:ian)

    assert Folder.find(folders(:ian_documents).id)
    assert Folder.find(folders(:jason_documents).id)

    assert Folder.restricted_find(folders(:ian_documents).id)
    assert_raises(ActiveRecord::RecordNotFound){ Folder.restricted_find(folders(:jason_documents).id) }
  end
  
  def test_cant_create_under_Documents_folder
    User.current = users(:ian)
    documents_folder = User.current.files_documents_folder
    folder = User.current.folders.create(:name => 'Test Folder', :parent_id => documents_folder.id, :organization_id => User.current.organization.id)

    assert ! folder.valid?
    assert_equal 1, folder.errors.length
    assert_not_nil folder.errors.on(:parent_id)
  end
end