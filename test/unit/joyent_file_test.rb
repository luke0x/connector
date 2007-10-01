=begin #(fold)
Copyright 2004-2007 Joyent Inc.

Redistribution and/or modification of this code is governed
by either the GPLv2 or Joyent Commercial Software licenses.

Report issues and contribute at http://dev.joyent.com/

$Id$
=end #(end)

require File.dirname(__FILE__) + '/../test_helper'

class JoyentFileTest < Test::Unit::TestCase
  fixtures all_fixtures
  include CRUDTest
  
  crud_data 'organization_id' => 1,
            'user_id'         => 1,
            'folder_id'       => 2,
            'filename'        => 'baz.png',
            'size_in_bytes'   => 2048,
            'notes'           => 'A picture of my dog.',
            'joyent_file_type_description' => 'Image'
            
  crud_required 'organization_id', 'user_id', 'filename', 'size_in_bytes', 'folder_id'

  def setup
    User.current = users(:ian)
    fill_root_paths
  end

  def test_crud
    run_crud_tests
  end

  def test_filename_without_extension
    assert_equal 'foo', joyent_files(:ian_jpg).filename_without_extension
  end
  
  def test_extension
    assert_equal '.jpg', joyent_files(:ian_jpg).extension
  end
  
  def test_extension_without_dot
    assert_equal 'jpg', joyent_files(:ian_jpg).extension_without_dot
  end
  
  def test_to_s_is_filename
    assert_equal 'foo.jpg', joyent_files(:ian_jpg).to_s
  end
  
  def test_pathname
    assert_equal "Documents/foo.jpg", joyent_files(:ian_jpg).pathname
  end
  
  def test_move_to
    f = joyent_files(:ian_jpg)
    old_path = f.path_on_disk
    f.move_to(folders(:ian_pictures))
    new_path = f.path_on_disk
    
    assert MockFS.file.exist?(new_path)
    assert_not_equal new_path, old_path
    assert !MockFS.file.exist?(old_path)
    f.move_to(folders(:ian_documents))
  end
  
  def test_copy_to_and_remove
    f = joyent_files(:ian_jpg)
    f.path_on_disk
    
    
    new_file = f.copy_to(folders(:ian_pictures))
    
    assert_equal folders(:ian_pictures), new_file.folder
    assert_not_equal folders(:ian_pictures), f.folder
    assert MockFS.file.exist?(f.path_on_disk)
    assert MockFS.file.exist?(new_file.path_on_disk)

    nid = new_file.id
    new_file.remove!
    assert MockFS.file.exist?(f.path_on_disk)
    assert !MockFS.file.exist?(new_file.path_on_disk)
    
    assert_raises(ActiveRecord::RecordNotFound) {JoyentFile.find(nid)}
  end
  
  def test_copy_to_preserves_permissions
    f = joyent_files(:ian_jpg)
    new_file = f.copy_to(folders(:ian_pictures))
    
    assert_equal f.permissions.collect(&:user).collect(&:username).sort, 
                 new_file.permissions.collect(&:user).collect(&:username).sort
    
    # first implementation was crap             
    assert (f.permissions.collect(&:id) & new_file.permissions.collect(&:id)).empty?
  end
  
  
  def test_add_permission
    f = joyent_files(:ians_dog_jpg)
    f.add_permission(users(:peter))
    
    f.reload
    
    assert_equal ["ian", "peter"], f.permissions.collect(&:user).collect(&:username).sort
  end  
  
  
  def test_remove_permission
    f = joyent_files(:ian_jpg)
    f.remove_permission(users(:peter))
    
    f.reload
    
    assert_equal ["ian"], f.permissions.collect(&:user).collect(&:username).sort
  end
  
  def test_make_public
    f = joyent_files(:ian_jpg)
    assert_not_equal [], f.permissions(true).collect(&:user)
    f.make_public!
    
    f.reload
    
    assert_equal [], f.permissions(true).collect(&:user)
  end
  
  def test_users_with_permission
    f = joyent_files(:ian_jpg)
    assert_equal ["ian", "peter"], f.users_with_permissions.collect(&:username).sort
    
    f = joyent_files(:jasons_cat)
    assert_equal ["jason", "uwr"], f.users_with_permissions.collect(&:username).sort
  end
  
  def test_notifications_removed_when_security_enhanced
    u = users(:peter)
    f = joyent_files(:ian_jpg)
    u.notify_of(f, users(:ian))
    
    f.reload
        
    assert f.notifications.map(&:notifiee_id).index(u.id)
    
    f.remove_permission(u)
    
    f.reload
    
    assert !f.notifications.map(&:notifiee_id).index(u.id)
  end

  def test_preview_text
    f = joyent_files(:ian_jpg)
    assert_equal String, f.preview_text.class
    assert f.preview_text.length > 0
  end
  
  def test_restricted_find_with_different_owner
    f = joyent_files(:peter_jpg)
    User.current=          users(:ian)
    
    assert_equal f, JoyentFile.restricted_find(f.id)
    assert_equal 'foopeter.jpg', f.name
  end 
  
  def test_permissions
    file         = joyent_files(:ian_jpg)
    User.current = users(:peter)
    assert file.permission_for(users(:peter))

    User.current = users(:ian)
    file.remove_permission(users(:peter))
    assert_nil file.permission_for(users(:peter))
  end   
        
  def test_permissions_arent_changed_by_restricted_find    
    user         = users(:peter)
    file         = joyent_files(:ian_jpg)
    User.current = user

    f = JoyentFile.restricted_find(file.id)
    assert_equal 2, f.permissions.size
    # This isn't actually something to assert, but it indicates
    # the problems we had with #restricted_find
    #assert_equal 1, f.hax_permissions.size
  end
                
  # I want to make sure that save doesn't rename the file to a bad name b/c it thinks
  # it found a duplicate (ensure_uniqueness)
  def test_save
    file     = joyent_files(:ian_jpg)
    filename = file.filename

    assert_equal file.filename, filename

    file.save                     
    assert_equal file.filename, filename

    file.save
    assert_equal file.filename, filename
  end

  def test_human_name
    assert_equal 'File', joyent_files(:ian_jpg).class_humanize
  end
  
end
