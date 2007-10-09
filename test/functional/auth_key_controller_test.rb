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
require 'auth_key_controller'

# Re-raise errors caught by the controller.
class AuthKeyController; def rescue_action(e) raise e end; end

class AuthKeyControllerTest < Test::Unit::TestCase
  fixtures :organizations, :users, :domains
  
  def setup
    @controller = AuthKeyController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new

    AuthKey.destroy_all
    @request.host = domains(:joyent).web_domain
  end

  def test_key_good    
    post :key, :username => users(:ian).username, :password => users(:ian).plaintext_password
    
    assert_response :success
    
    assert(key = AuthKey.find(:first))
    
    assert_equal key.key, @response.body
  end
  
  def test_key_bad_password
    post :key, :username => users(:ian).username, :password => 'blahblahsdfa'    
    assert_key_gen_failed
  end
  
  def test_key_bad_domain
    @request.host = 'foobar.com'
    post :key, :username => users(:ian).username, :password => 'blahblahsdfa'
    assert_key_gen_failed
  end
  
  def test_key_bad_user_id_org_id_combo
    @request.host = domains(:textdrive).web_domain
    post :key, :username => users(:ian).username, :password => users(:ian).plaintext_password
    assert_key_gen_failed
  end
  
  private
  def assert_key_gen_failed
    assert_response 401
    assert_equal 0, AuthKey.count    
  end
end
