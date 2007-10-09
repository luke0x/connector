=begin #(fold)
++
Copyright 2004-2007 Joyent Inc.

Redistribution and/or modification of this code is 
governed by the GPLv2.

Report issues and contribute at http://dev.joyent.com/

$Id$
--
=end #(end)

require "#{File.dirname(__FILE__)}/../test_helper"

class AuthenticationStories < ActionController::IntegrationTest
  fixtures all_fixtures
  
  # These are kind of just examples, nothing too serious just yet.
  def test_go_to_login
    new_session(:joyent) do |sess|
      sess.goes_to_login
    end
  end
  
  def test_user_logs_in
    new_session_as(:ian)
  end
  
  def test_user_logs_out
    new_session_as(:ian) do |sess|
      sess.logs_out
    end
  end
  
  def test_logged_in_can_access_connect
    new_session_as(:ian) do |sess|
      sess.get connector_home_url
      sess.assert_response :redirect
      sess.assert_redirected_to reports_index_url
    end
  end
  
  def test_not_logged_in_cannot_access_connect
    new_session(:joyent) do |sess|
      sess.get connector_home_url
      sess.assert_response :redirect
      sess.follow_redirect!
      sess.assert_template 'authenticate/login'
    end
  end
  
  def test_login_with_cookie
    new_session(:textdrive) do |sess|
      sess.cookies['sso_remember'] = 'true'
      sess.cookies['sso_token_value'] = login_tokens(:imnew).value
      sess.get connector_home_url

      sess.assert_response :redirect
      sess.assert_redirected_to reports_index_url
      sess.assert_equal true, sess.session[:sso_verified]
      assert_equal users(:jason).id, LoginToken.find_by_value(sess.cookies['sso_token_value']).user_id
    end
  end
  
  def test_login_with_bad_cookie
    new_session(:textdrive) do |sess|
      sess.cookies['sso_remember'] = login_tokens(:ianlogin).value
      sess.get connector_home_url
      sess.assert_response :redirect
      sess.follow_redirect!
      sess.assert_template 'authenticate/login'
    end
  end

  def test_login_remembers_and_goes_to_requested_page
    uri = '/files/1?awesome=true'

    new_session(:joyent) do |sess|
      sess.get uri
      sess.assert_response :redirect
      sess.follow_redirect!
      sess.assert_template 'authenticate/login'
      sess.assert_equal uri, sess.session[:post_login_url]

      sess.post login_url, :username => users(:ian).username, :password => users(:ian).plaintext_password
      sess.assert_redirected_to uri
      sess.follow_redirect!
      sess.assert_template 'files/list'
    end
  end
  
  def test_user_resets_password
    new_session(:joyent) do |sess|
      sess.goes_to_login
      sess.post reset_password_url, :username => users(:ian).username
      sess.assert_equal nil, sess.flash[:error]
      
      sess.get verify_reset_password_url, :token => User.find_by_username('ian').recovery_token
      sess.assert_response :success
      
      sess.post verify_reset_password_url, :password => 'testing', :password_confirmation => 'testing', :token => User.find_by_username('ian').recovery_token
      sess.assert_redirected_to connector_home_url
    end
  end
  
end