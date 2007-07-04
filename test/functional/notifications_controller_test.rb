=begin #(fold)
Copyright 2004-2007 Joyent Inc.

Redistribution and/or modification of this code is governed
by either the GPLv2 or Joyent Commercial Software licenses.

Report issues and contribute at http://dev.joyent.com/

$Id$
=end #(end)

require File.dirname(__FILE__) + '/../test_helper'
require 'notifications_controller'

# Re-raise errors caught by the controller.
class NotificationsController; def rescue_action(e) raise e end; end

class NotificationsControllerTest < Test::Unit::TestCase
  fixtures all_fixtures
  def setup
    @controller = NotificationsController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
  end

  def test_notify
    login_person(:ian)
    @request.env["HTTP_REFERER"] = '/files/1'
    assert_equal 0, joyent_files(:ian_jpg).notifications.length
    assert_equal 0, users(:peter).current_notifications.select{|n| n.item_id == joyent_files(:ian_jpg).id and n.item_type == joyent_files(:ian_jpg).class.to_s}.length
    post :create, {:dom_ids => joyent_files(:ian_jpg).dom_id, :user_id => users(:peter).id}

    assert_response :redirect
    assert assigns(:user)
    joyent_files(:ian_jpg).reload
    assert_equal 1, joyent_files(:ian_jpg).notifications.length
    assert_equal 1, users(:peter).current_notifications(true).select{|n| n.item_id == joyent_files(:ian_jpg).id and n.item_type == joyent_files(:ian_jpg).class.to_s}.length
  end
                       
  # regression for 2974
  def test_notify_twice
    login_person(:ian)
    @request.env["HTTP_REFERER"] = '/people'
    assert_equal 0, joyent_files(:ian_jpg).notifications.length
    assert_equal 0, users(:peter).current_notifications.select{|n| n.item_id == joyent_files(:ian_jpg).id and n.item_type == joyent_files(:ian_jpg).class.to_s}.length
    post :create, {:dom_ids => joyent_files(:ian_jpg).dom_id, :user_id => users(:peter).id}

    assert_response :redirect
    assert assigns(:user)
    joyent_files(:ian_jpg).reload
    assert_equal 1, joyent_files(:ian_jpg).notifications.length
    assert_equal 1, users(:peter).current_notifications(true).select{|n| n.item_id == joyent_files(:ian_jpg).id and n.item_type == joyent_files(:ian_jpg).class.to_s}.length    
    assert !@response.body.blank?
        
    post :create, {:dom_ids => joyent_files(:ian_jpg).dom_id, :user_id => users(:peter).id}                              
    assert_response :redirect
    assert assigns(:user)
    joyent_files(:ian_jpg).reload
    assert_equal 2, joyent_files(:ian_jpg).notifications.length
    assert_equal 1, users(:peter).current_notifications(true).select{|n| n.item_id == joyent_files(:ian_jpg).id and n.item_type == joyent_files(:ian_jpg).class.to_s}.length
    assert !@response.body.blank?
  end
  
  # regression for 2974
  def test_unnotify_twice
    login_person(:ian)
    @request.env["HTTP_REFERER"] = '/calendar'
    assert_equal 1, events(:peter_concert).active_notifications.length
    notification_id = notifications(:ian_check_it).id
    post :delete, {:dom_ids => events(:peter_concert).dom_id, :user_id => users(:ian).id}

    assert_response :redirect
    events(:peter_concert).reload
    assert_equal 0, events(:peter_concert).active_notifications.length
    assert !@response.body.blank?   
    
    post :delete, {:notification_id => notification_id, :dom_ids => events(:peter_concert).dom_id}

    assert_response :success
    events(:peter_concert).reload
    assert_equal 0, events(:peter_concert).active_notifications.length      
    assert @response.body.blank?
  end
  
  def test_unnotify
    login_person(:ian)
    @request.env["HTTP_REFERER"] = '/calendar'
    assert_equal 1, events(:peter_concert).active_notifications.length
    post :delete, {:user_id => notifications(:ian_check_it).notifiee_id, :dom_ids => notifications(:ian_check_it).item.dom_id}
    
    assert_response :redirect
    events(:peter_concert).reload
    assert_equal 0, events(:peter_concert).active_notifications.length
  end
  
  def test_acknowledge
    login_person(:ian)
    assert ! notifications(:ian_check_it).acknowledged?
    post :acknowledge, {:id => notifications(:ian_check_it).id}

    notifications(:ian_check_it).reload
    assert notifications(:ian_check_it).acknowledged?
  end

  def test_notify_not_permitted_item
    login_person(:user_with_restrictions)
    @request.env["HTTP_REFERER"] = '/people'
    assert_equal 1, people(:secret_person).notifications.length
    post :create, {:dom_ids => people(:secret_person).dom_id, :user_id => users(:jason).id}

    assert_equal 1, people(:secret_person).notifications.length
    assert_response :redirect
  end

  def test_unnotify_not_permitted_item
    login_person(:user_with_restrictions)
    assert_equal 1, people(:secret_person).notifications.length
    post :delete, {:notification_id => notifications(:secret_person_notify_youself).id}

    assert_equal 1, people(:secret_person).notifications.length
    assert_response :success
    assert_equal ' ', @response.body 
  end

  def test_notify_non_item_type
    login_person(:user_with_restrictions)
    @request.env["HTTP_REFERER"] = '/people'
    assert_equal 1, people(:secret_person).notifications.length
    post :create, {:dom_ids => 'fellini_4', :user_id => users(:jason).id}

    assert_equal 1, people(:secret_person).notifications.length
    assert_response :redirect
  end

  def test_unnotify_item_with_invalid_id
    login_person(:user_with_restrictions)
    assert_equal 1, people(:secret_person).notifications.length
    post :delete, {:notification_id => 999999}

    assert_equal 1, people(:secret_person).notifications.length
    assert_response :success
    assert_equal ' ', @response.body
  end

  def test_acknowledge_not_permitted_item
    login_person(:user_with_restrictions)
    assert ! notifications(:ian_check_it).acknowledged?
    post :acknowledge, {:id => notifications(:ian_check_it).id}

    notifications(:ian_check_it).reload
    assert ! notifications(:ian_check_it).acknowledged?
  end

end
