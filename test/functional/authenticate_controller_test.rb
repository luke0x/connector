=begin #(fold)
Copyright 2004-2007 Joyent Inc.

Redistribution and/or modification of this code is governed
by either the GPLv2 or Joyent Commercial Software licenses.

Report issues and contribute at http://dev.joyent.com/

$Id$
=end #(end)

require File.dirname(__FILE__) + '/../test_helper'
require 'authenticate_controller'

# Re-raise errors caught by the controller.
class AuthenticateController; def rescue_action(e) raise e end; end

class AuthenticateControllerTest < Test::Unit::TestCase
  fixtures all_fixtures
  
  def setup
    @controller   = AuthenticateController.new
    @request      = ActionController::TestRequest.new
    @response     = ActionController::TestResponse.new
    @request.host = domains(:joyent).web_domain
  end

  def test_login_form
    get :login
    assert_response :success
    assert_template 'login'
  end
  
  def test_login
    assert_nil @request.session[:sso_verified]
    assert_nil @response.cookies['sso_token_value']

    post :login, :username => users(:ian).username,
                 :password => users(:ian).plaintext_password

    assert_not_nil @request.session[:sso_verified]
    assert_not_nil @response.cookies['sso_token_value']
    assert_equal users(:ian).id, LoginToken.find_by_value(@response.cookies['sso_token_value']).user_id
    assert_redirected_to connector_home_url
  end
  
  def test_login_with_blank_password
    post :login, :username => users(:ian).username, :password => ''
    
    assert_response :success
    assert_template 'login'
    assert flash[:login_error]
  end
  
  def test_login_doesnt_set_sso_remember_cookie
    post :login, :username => users(:ian).username,
                 :password => users(:ian).plaintext_password

    assert_redirected_to connector_home_url
    assert @response.cookies['sso_remember'].blank?
  end
  
  def test_invalid_login
    post :login, :username => users(:ian).username,
                 :password => 'mickeymouse'

    assert_response :success
    assert_template 'login'
    assert flash[:login_error]
  end
  
  def test_logout
    get :logout, {}, {:user_id=>1}
    
    assert_redirected_to login_url
    assert_nil session[:sso_verified]
    assert_nil session[:sso_token_value]
  end
  
  def test_logout_with_token_destroys_token_and_cookie
    login_person(:ian)
    assert_equal 3, LoginToken.count
    get :logout
    
    assert_redirected_to login_url
    assert_nil session[:sso_verified]
    assert @response.cookies['sso_token_value'].blank?
    assert @response.cookies['sso_remember'].blank?
    assert_equal 2, LoginToken.find(:all).length
  end
  
  def test_get_index_sends_you_to_the_connect_screen
    login_person(:ian)
    get :index, {}
    assert_redirected_to connector_home_url
  end
  
  def test_get_index_when_not_logged_in_redirects_to_login
    get :index, {}
    assert_response :redirect
  end
end