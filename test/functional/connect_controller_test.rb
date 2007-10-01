=begin #(fold)
Copyright 2004-2007 Joyent Inc.

Redistribution and/or modification of this code is governed
by either the GPLv2 or Joyent Commercial Software licenses.

Report issues and contribute at http://dev.joyent.com/

$Id$
=end #(end)

require File.dirname(__FILE__) + '/../test_helper'
require 'connect_controller'
require 'flexmock'

# Re-raise errors caught by the controller.
class ConnectController; def rescue_action(e) raise e end; end

class ConnectControllerTest < Test::Unit::TestCase
  include FlexMock::TestCase
  
  fixtures all_fixtures
  
  def setup
    @controller = ConnectController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
    login_person(:ian)
  end

  def test_index
    get :index

    assert_response :redirect
    assert_redirected_to reports_index_url
  end
  
  def test_smart_group_attributes_are_right
    get :notifications
    assert_response :success
    assert_smart_group_attributes_assigned smart_group_descriptions(:everything)
  end
  
  def test_smart_list
    get :smart_list, {:smart_group_id => "s1"}
    assert_response :success
    assert assigns(@items)
    assert assigns(@group_name)
  end                         
  
  def test_smart_list_ajax
    xhr :get, :smart_list, {:smart_group_id => "s1"}
    assert_response :success
    assert assigns(@items)
    assert assigns(@group_name)    
  end

  def test_notifications
    get :notifications

    assert_response :success
    assert assigns(:notifications)
    assert_toolbar([:all_notifications])
  end
  
  def test_notifications_ajax
    xhr :get, :notifications

    assert_response :success
    assert assigns(:notifications)
  end

  def test_all_notifications
    get :notifications, {:all => ''}

    assert_response :success
    assert assigns(:notifications)
    assert_toolbar([:new_notifications])
  end
  
  def test_search
    get :search, {:search_string=>"omgomgomg"}
    assert_response :success
    assert assigns(:items)
  end

  def test_search_stays_on_org
    get :search, {:search_string=>"joyent"}
    assert_equal 1, assigns(:items).select{|i| i.is_a?(Bookmark)}.length
    assert_equal 2, Bookmark.count     
    org_id = assigns(:items).first.organization_id
    assigns(:items).each do |item|
      assert_equal org_id, item.organization_id
    end
  end
  
  def test_search_with_magic_phrase
    get :search, {:search_string=>"foo"}
    assert_response :success
    assert assigns(:items)
  end

  def test_save_search
    i = SmartGroup.count
    get :save_search, {:search_string => 'foo'}
    
    assert_equal i + 1, SmartGroup.count
    assert_response :redirect
    assert_redirected_to connector_home_url
  end

  def test_save_search_invald
    i = SmartGroup.count
    get :save_search

    assert_equal i, SmartGroup.count
    assert_response :redirect
    assert_redirected_to connector_home_url
  end
  
  def test_inactive_orgs_dont_work
    login_person(:ian)
    get :notifications
    assert_response :success

    organizations(:joyent).deactivate!
    get :notifications
    assert_redirected_to '/deactivated.html'
  end
  
  def test_smart_group
    login_person(:ian)
    get :smart_list, {:smart_group_id => smart_groups(:ian_everything_from_peter).url_id}
    assert_response :success
    assert_template 'list'
  end    
  
  def test_recent_comments
    get :recent_comments      
    assert assigns(:comments)
    assert_response :success
  end                     
  
  def test_recent_comments_ajax
    xhr :get, :recent_comments
    assert assigns(:comments)
    assert_response :success    
  end

  def test_lightning_portal
    login_person(:ian)
    get :lightning_portal
    assert_response :success
    assert_template 'lightning_portal'
  end
  
end
