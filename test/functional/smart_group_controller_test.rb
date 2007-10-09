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
require 'smart_group_controller'

# Re-raise errors caught by the controller.
class SmartGroupController; def rescue_action(e) raise e end; end

class SmartGroupControllerTest < Test::Unit::TestCase
  fixtures all_fixtures

  def setup
    @controller = SmartGroupController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
    login_person(:ian)
    @request.env["HTTP_REFERER"] = '/mail/mailbox/inbox'
  end

  def test_create
    post :create, :smart_group_name => 'Test Smart Group',
                  :boolean_mode => 'all',
                  :smart_group_description_id => smart_group_descriptions(:messages).id,
                  :tag => {'1' => 'awesome'},
                  :attribute => {'1' => {:value => 'message', :key => smart_group_attribute_descriptions(:message_subject).id}}

    assert assigns(:smart_group).id > 0
    assert_response :redirect
    assert_redirected_to mail_special_list_url(:id => 'inbox')
  end

  def test_delete
    assert SmartGroup.find_by_id(smart_groups(:ian_foo_mail).id)
    post :delete, :id => smart_groups(:ian_foo_mail).id

    assert ! SmartGroup.find_by_id(smart_groups(:ian_foo_mail).id)
    assert_response :redirect
    assert_redirected_to mail_special_list_url(:id => 'inbox')
  end

  def test_delete_restricted
    assert SmartGroup.find_by_id(smart_groups(:jason_foo_events).id)
    post :delete, :id => smart_groups(:ian_foo_mail).id

    assert SmartGroup.find_by_id(smart_groups(:jason_foo_events).id)
    assert_response :redirect
    assert_redirected_to mail_special_list_url(:id => 'inbox')
  end

  def test_update
    assert_equal 1, SmartGroup.find_by_id(smart_groups(:ian_foo_mail).id).tags.length
    assert_equal 0, SmartGroup.find_by_id(smart_groups(:ian_foo_mail).id).smart_group_attributes.length
    post :update, :id => smart_groups(:ian_foo_mail).id,
                  :smart_group_name => 'Emails tagged foo and bar',
                  :boolean_mode => 'all',
                  :smart_group_description_id => smart_group_descriptions(:messages).id,
                  :tag => {'1' => 'foo', '2' => 'bar'},
                  :attribute => {'1' => {:value => 'message', :key => smart_group_attribute_descriptions(:message_subject).id}}

    assert assigns(:smart_group)
    assert_equal 2, SmartGroup.find_by_id(smart_groups(:ian_foo_mail).id).tags.length
    assert_equal 1, SmartGroup.find_by_id(smart_groups(:ian_foo_mail).id).smart_group_attributes.length
    assert_response :redirect
    assert_redirected_to mail_special_list_url(:id => 'inbox')
  end

  def test_rename
    assert_equal smart_groups(:ian_everything_from_peter).name, 'Everything Owned By Peter'
    post :rename, :id => smart_groups(:ian_everything_from_peter).id, :name => 'Agile'
    smart_groups(:ian_everything_from_peter).reload
    assert_equal smart_groups(:ian_everything_from_peter).name, 'Agile'
    assert_response :redirect
  end

  def test_dont_rename
    assert_equal smart_groups(:ian_everything_from_peter).name, 'Everything Owned By Peter'
    post :rename, :id => smart_groups(:ian_everything_from_peter).id, :name => ''
    smart_groups(:ian_everything_from_peter).reload
    assert_equal smart_groups(:ian_everything_from_peter).name, 'Everything Owned By Peter'
  end

end 