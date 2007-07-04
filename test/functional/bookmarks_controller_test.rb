=begin #(fold)
Copyright 2004-2007 Joyent Inc.

Redistribution and/or modification of this code is governed
by either the GPLv2 or Joyent Commercial Software licenses.

Report issues and contribute at http://dev.joyent.com/

$Id$
=end #(end)

require File.dirname(__FILE__) + '/../test_helper'
require 'bookmarks_controller'

# Re-raise errors caught by the controller.
class BookmarksController; def rescue_action(e) raise e end; end

class BookmarksControllerTest < Test::Unit::TestCase
  fixtures all_fixtures

  def setup
    @controller = BookmarksController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
    @request.env["HTTP_REFERER"] = '/bookmarks'
    login_person(:ian)
  end

  def test_index
    get :index

    assert_response :redirect
    assert_redirected_to bookmarks_list_route_url(:bookmark_folder_id => bookmark_folders(:ian_bookmark_folder))
  end
  
  def test_list
    get :list, {:bookmark_folder_id => bookmark_folders(:ian_bookmark_folder).id}

    assert_response :success
    assert assigns(:view_kind)
    assert assigns(:group_name)
    assert assigns(:bookmark_folder)
    assert assigns(:bookmarks)
    assert assigns(:paginator)
  end
  
  def test_list_everyone
    get :list_everyone

    assert_response :success
    assert assigns(:view_kind)
    assert assigns(:group_name)
    assert assigns(:bookmarks)
    assert assigns(:paginator)
  end
  
  def test_show
    get :show, {:id => bookmarks(:ian_bookmark_1).id}

    assert_response :success
    assert assigns(:view_kind)
    assert assigns(:bookmark_folder)
    assert assigns(:bookmark)
  end
  
  def test_create_get
    get :create

    assert_response :success
    assert assigns(:view_kind)
    assert assigns(:bookmark)
  end
  
  # def test_create_post
  #   post :create, {}
  # end

  def test_create_via_bookmarklet
    get :show, {:id => bookmarks(:ian_bookmark_1).id}
    assert_response :success
    @request.env['REQUEST_URI'] = nil

    get :create, {:uri => 'http://joyent.com/', :title => 'Joyent', :via => 'bookmarklet'}
    assert_response :success
  end

  def test_edit_get
    get :edit, {:id => bookmarks(:ian_bookmark_1).id}

    assert_response :success
    assert assigns(:view_kind)
    assert assigns(:bookmark)
    assert assigns(:group_name)
  end

  # def test_edit_post
  #   post :edit, {}
  # end

  # def test_delete
  # end

  def test_peek
    xhr :get, :show, {:id => bookmarks(:ian_bookmark_1).id}

    assert assigns(:bookmark)
    assert_response :success
  end

  def test_copy
    bookmarks_count = users(:ian).bookmarks.length
    get :copy, {:ids => bookmarks(:ian_bookmark_1).id}

    assert_equal users(:ian).reload.bookmarks.length, bookmarks_count + 1
    assert_response :redirect
  end

  def test_notifications
    get :notifications
    
    assert_response :success
    assert assigns(:view_kind)
    assert assigns(:group_name)
    assert_equal false, assigns(:show_all)
    assert assigns(:notifications)
    assert assigns(:paginator)
  end

  def test_smart_list
    get :smart_list, {:smart_group_id => "s#{smart_groups(:ian_secure_bookmarks).id}"}

    assert_response :success
    assert assigns(:view_kind)
    assert assigns(:smart_group)
    assert assigns(:group_name)
    assert assigns(:paginator)
    assert assigns(:bookmarks)
  end

  def test_external_show
    get :external_show, {:id => 4}

    assert_response :redirect
    assert_redirected_to bookmarks_show_url(:id => 4)
  end

end
