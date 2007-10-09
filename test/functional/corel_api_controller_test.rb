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
require 'corel_api_controller'
require 'flexmock'

# Re-raise errors caught by the controller.
class CorelApiController; def rescue_action(e) raise e end; end

class CorelApiControllerTest < Test::Unit::TestCase
  include FlexMock::TestCase
  
  fixtures :organizations, :users, :domains
  
  def setup
    @controller = CorelApiController.new
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
  
  
  
  def test_user_info_good
    post :user_info, :username => users(:ian).username, :password => users(:ian).plaintext_password
    
    assert_response :success
    # ...
  end
  
  def test_user_info_bad_password
    post :user_info, :username => users(:ian).username, :password => 'blahblahsdfa'    
    assert_response 401
  end
  
  def test_user_info_bad_domain
    @request.host = domains(:textdrive).web_domain
    post :user_info, :username => users(:ian).username, :password => 'blahblahsdfa'
    assert_response 401
  end
  
  def test_user_info_bad_user_id_org_id_combo
    post :user_info, :username => users(:ian).username, :password => 'blahblahsdfa'
    assert_response 401    
  end




  def test_set_language_good
    post :set_language, :username => users(:ian).username, :password => users(:ian).plaintext_password, :language => 'es'
    
    assert_response :success
    assert_equal 'es', users(:ian).get_option('Language')
  end
  
  def test_set_language_bad_password
    post :set_language, :username => users(:ian).username, :password => 'blahblahsdfa', :language => 'es'
    assert_response 401
  end
  
  def test_set_language_bad_domain
    @request.host = domains(:textdrive).web_domain
    post :set_language, :username => users(:ian).username, :password => 'blahblahsdfa', :language => 'es'
    assert_response 401
  end
  
  def test_set_language_bad_user_id_org_id_combo
    post :set_language, :username => users(:ian).username, :password => 'blahblahsdfa', :language => 'es'
    assert_response 401    
  end
  
  def test_set_lanaguge_bad_language
    post :set_language, :username => users(:ian).username, :password => users(:ian).plaintext_password
    assert_response 400
    assert_equal 4096, @response.body.to_i
  end



  def test_reset_password_good
    pw = users(:ian).plaintext_password
    post :reset_password, :username => users(:ian).username, :email => users(:ian).recovery_email
    
    assert_response :success
    assert_not_equal pw, users(:ian).reload.plaintext_password
  end
  
  def test_reset_password_bad_email
    post :reset_password, :username => users(:ian).username, :email => 'foo@bar.com'
    assert_response 401
  end
  
  def test_reset_password_bad_domain
    @request.host = domains(:textdrive).web_domain
    post :reset_password, :username => users(:ian).username, :email => users(:ian).recovery_email
    assert_response 401
  end
  
  def test_reset_password_bad_username
    post :reset_password, :username => 'foobar', :email => users(:ian).recovery_email
    assert_response 401    
  end




  def test_update_password_good
    post :update_password, :username => users(:ian).username, :old_password => users(:ian).plaintext_password, :new_password => 'foobar'
    
    assert_response :success
    assert_equal 'foobar', users(:ian).reload.plaintext_password
  end
  
  def test_update_password_bad_password
    post :update_password, :username => users(:ian).username, :old_password => 'blahblahsdfa', :new_password => 'foobar'
    assert_response 401
  end
  
  def test_update_password_bad_domain
    @request.host = domains(:textdrive).web_domain
    post :update_password, :username => users(:ian).username, :old_password => 'blahblahsdfa', :new_password => 'foobar'
    assert_response 401
  end
    
  def test_update_password_bad_new_password
    post :update_password, :username => users(:ian).username, :old_password => users(:ian).plaintext_password, :new_password => ''
    
    assert_response 400
    assert_equal 16, @response.body.to_i
  end

  def test_update_password_short_new_password
    post :update_password, :username => users(:ian).username, :old_password => users(:ian).plaintext_password, :new_password => 'x'
    
    assert_response 400
    assert_equal 16, @response.body.to_i
  end



  
  private
  def assert_key_gen_failed
    assert_response 401
    assert_equal 0, AuthKey.count    
  end
end
