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
require 'subscriptions_controller'

# Re-raise errors caught by the controller.
class SubscriptionsController; def rescue_action(e) raise e end; end

class SubscriptionsControllerTest < Test::Unit::TestCase
  fixtures all_fixtures
  def setup
    @controller = SubscriptionsController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
    login_person(:ian)
  end

  def test_subscribe
    get :subscribe, {:subscribable_id => 14, :organization_id => 1, :user_id => 1, :subscribable_type => 'Folder'}
    
    assert Subscription.find_by_subscribable_id 14
    assert_response :success
  end
  
  def test_unsubscribe
    post :unsubscribe, {:subscription_id => 11}
    
    assert_raises(ActiveRecord::RecordNotFound) {Subscription.find(11)} 
    assert_redirected_to '/home'
  end
  
end
