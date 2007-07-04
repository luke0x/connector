=begin #(fold)
Copyright 2004-2007 Joyent Inc.

Redistribution and/or modification of this code is governed
by either the GPLv2 or Joyent Commercial Software licenses.

Report issues and contribute at http://dev.joyent.com/

$Id$
=end #(end)

module IntegrationDSL
  def goes_to_login
    get login_url

    assert_response :success
    assert_template 'authenticate/login'
  end
  
  def logs_in_as(user)
    @user = users(user)
    post login_url, :username => @user.username, :password => @user.plaintext_password

    assert_response :redirect
    follow_redirect!

    assert_response :redirect
    assert_redirected_to reports_index_url
    assert_equal session[:sso_verified], true
    assert_equal cookies['sso_token_value'], @user.login_token.value
  end
  
  def logs_out
    get logout_url
    
    assert_response :redirect
    follow_redirect!
    assert_template 'authenticate/login'
    assert_nil session[:sso_verified]
  end
end