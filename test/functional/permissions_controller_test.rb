=begin #(fold)
Copyright 2004-2007 Joyent Inc.

Redistribution and/or modification of this code is governed
by either the GPLv2 or Joyent Commercial Software licenses.

Report issues and contribute at http://dev.joyent.com/

$Id$
=end #(end)

require File.dirname(__FILE__) + '/../test_helper'
require 'permissions_controller'

# Re-raise errors caught by the controller.
class PermissionsController; def rescue_action(e) raise e end; end

class PermissionsControllerTest < Test::Unit::TestCase
  fixtures all_fixtures
  def setup
    @controller = PermissionsController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
    login_person(:ian)
  end

  def test_add_user
    @request.env["HTTP_REFERER"] = '/calendar'
    assert_equal 0, events(:concert).permissions.length
    get :add_user, {:dom_ids => events(:concert).dom_id, :user_id => users(:ian).id}

    assert_response :redirect
    events(:concert).reload
    assert_equal 1, events(:concert).permissions.length
  end
  
  def test_remove_user                                      
    # First we need to disassociate the ian and peter users
    peter  = users(:peter)
    peter.identity = Identity.new(:name => 'loner')
    peter.save
    
    @request.env["HTTP_REFERER"] = '/files'
    assert users(:peter).can_view?(joyent_files(:ian_jpg))
    get :remove_user, {:dom_ids => joyent_files(:ian_jpg).dom_id, :user_id => users(:peter).id}

    assert_response :redirect
    joyent_files(:ian_jpg).permissions(true)
    assert ! users(:peter).can_view?(joyent_files(:ian_jpg))
  end
  
  def test_make_public
    @request.env["HTTP_REFERER"] = '/files'
    assert joyent_files(:ian_jpg).permissions.length > 0
    get :make_public, {:dom_ids => joyent_files(:ian_jpg).dom_id}

    assert_response :redirect
    joyent_files(:ian_jpg).reload
    assert_equal 0, joyent_files(:ian_jpg).permissions(true).length
  end
  
  def test_set_group_permissions_make_private
    @request.env["HTTP_REFERER"] = '/files'
    m = mailboxes(:ian_inbox)
    assert_equal 0, m.permissions.length
    get :set_group_permissions, {:access_mode => 'restricted', :group_type => m.class.to_s, :id => m.id}

    assert_response :redirect
    m.reload
    assert_equal 1, m.permissions(true).length
  end
  
  def test_restrict_folder
    @request.env["HTTP_REFERER"] = "/foo"
    assert_equal 0, folders(:ian_pictures).permissions(true).length
    post :set_group_permissions, {:group_type=>'Folder', :id=>folders(:ian_pictures).id, :user_ids=>[users(:ian).id], 
                                  :access_mode=>'restricted'}
    assert_response :redirect
    assert_equal 1, folders(:ian_pictures).permissions(true).length
  end

  def test_make_public_folder
    @request.env["HTTP_REFERER"] = "/foo"
    assert folders(:ian_pictures_vacation).permissions(true).length > 0
    post :set_group_permissions, {:group_type=>'Folder', :id=>folders(:ian_pictures_vacation).id, 
                                  :access_mode=>'public'}
    assert_response :redirect
    assert_equal 0, folders(:ian_pictures_vacation).permissions(true).length
  end
end