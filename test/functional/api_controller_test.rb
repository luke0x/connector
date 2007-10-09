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
require 'api_controller'

# Re-raise errors caught by the controller.
class ApiController; def rescue_action(e) raise e end; end

class ApiControllerTest < Test::Unit::TestCase
  fixtures all_fixtures
  def setup
    @controller = ApiController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
    @request.env["HTTP_AUTHORIZATION"] = "Basic " + Base64.encode64("username:password")
  end
  
  def test_create_organization
    post :create_organization, {:organization=>{
              :name=>"Indent", 
              :active=>"true",
              :system_domain => "indent.joyent.net",
              :quota=> { :users=>5, :gigabytes=>5, :custom_domains=>true },
              :user => { :username => "justin",
                         :password => "french",
                         :first_name => "Justin",
                         :last_name => "French" } } }
  
    assert_response :success
    assert @response.body =~ /<id type="integer">(\d+)<\/id>/
    o = Organization.find($1.to_i)
    assert o.active?
    assert u = o.users.find_by_username("justin")
    assert_equal "french", u.plaintext_password
    assert_equal "Justin French", u.full_name
  end
  
  def test_update_organization
    post :update_organization, { :id=>organizations(:joyent).id,
      :organization=>{
      :name => "Tneyoj",
      :active => "false",
      :quota => {
        :users => 54,
        :gigabytes => 34,
        :custom_domains => false}}}
    assert_response :success
    o = organizations(:joyent)
    o.reload
    assert_equal "Tneyoj", o.name
    assert !o.active?
    assert_equal 54, o.quota(true).users
    assert_equal 34, o.quota.gigabytes
    assert !o.quota.custom_domains
  end
  
  
  def test_add_domain
    o = organizations(:joyent)
    post :create_domain, {:id=>o.id, :domain=>{:web_domain=>"home.joyent.biz", :email_domain=>"joyent.biz"}}
    assert_response :success
    
    assert_equal "home.joyent.biz", o.domains.find_by_email_domain("joyent.biz").web_domain
  end
 
  def test_add_domain
    o = organizations(:joyent)
    post :update_domain, {:id=>o.id, :domain_id=>1, :domain=>{:web_domain=>"homeo.joyent.biz", :email_domain=>"joyent.biz"}}
    assert_response :success
    
    assert_equal "homeo.joyent.biz", o.domains.find_by_email_domain("joyent.biz").web_domain
  end 
  
  def test_remove_domain
    o = organizations(:joyent)
    post :destroy_domain, {:id=>o.id, :domain_id=>domains(:joyent_dev).id}
    assert_response :success

    assert_nil Domain.find_by_id(domains(:joyent_dev).id)
  end
  
  # Need to lock an org before destroying it
  def test_destroy
    o = organizations(:joyent)
    post :destroy_organization, {:id=>o.id}
    assert_response :success
    
    assert Organization.find_by_id(o.id)
    
    post :lock_organization, {:id=>o.id}
    post :destroy_organization, {:id=>o.id}
    assert_response :success
    assert_nil Organization.find_by_id(o.id)    
  end
  
  def test_lock
    o = organizations(:joyent)
    post :lock_organization, {:id=>o.id}
    assert_response :success
    o.reload
    assert !o.active?
  end

  def test_unlock
    o = organizations(:joyent)
    post :unlock_organization, {:id=>o.id}
    assert_response :success
    o.reload
    assert o.active?
  end
  
  def test_add_domain
    o = organizations(:joyent)
    post :create_domain, {:id=>o.id, :domain=>{:primary => "false", 
    :web_domain => "slashdot.org", 
    :email_domain => "slashdot.org"}}
    assert_response :success
    assert o.domains.find_by_web_domain("slashdot.org")
    assert d = o.domains.find_by_email_domain("slashdot.org")
    assert !d.primary
    assert domains(:joyent).primary?
  end
  
  def test_add_domain_as_primary
    o = organizations(:joyent)
    post :create_domain, {:id=>o.id, :domain=>{:primary => "true", 
    :web_domain => "slashdot.org", 
    :email_domain => "slashdot.org"}}
    assert_response :success
    assert o.domains.find_by_web_domain("slashdot.org")
    assert d = o.domains.find_by_email_domain("slashdot.org")
    assert d.primary
    assert !domains(:joyent).primary?
  end
  
  def test_update_domain
    o = organizations(:joyent)
    d = domains(:joyent_net)
    
    post :update_domain, {:id=>o.id, :domain_id=>d.id, :domain=>{:web_domain=>"foo.com", :primary=>"false"}}
    assert_response :success
    d.reload
    assert !d.primary?
    assert_equal "foo.com", d.web_domain
  end
  
  def test_update_domain_to_primary
    o = organizations(:joyent)
    d = domains(:joyent_net)
    
    post :update_domain, {:id=>o.id, :domain_id=>d.id, :domain=>{:web_domain=>"foo.com", :primary=>"true"}}
    assert_response :success
    d.reload
    assert d.primary?
    assert_equal "foo.com", d.web_domain
  end
  
  def test_update_primary_domain_to_not_primary_should_be_ignored
    o = organizations(:joyent)
    d = domains(:joyent)
    
    post :update_domain, {:id=>o.id, :domain_id=>d.id, :domain=>{:web_domain=>"foo.com", :primary=>"false"}}
    assert_response :success
    d.reload
    assert d.primary?
    assert_equal "foo.com", d.web_domain
  end
  
  def test_destroy_domain_yells_at_system_domain
    o = organizations(:joyent)
    d = domains(:joyent)
    assert_raises(RuntimeError) do
      post :destroy_domain, {:id=>o.id, :domain_id=>d.id}
    end 
  end
  
  def test_destroy_domain
    o = organizations(:joyent)
    d = domains(:joyent_net)
    post :destroy_domain, {:id=>o.id, :domain_id=>d.id}
    assert_response :success
    assert_nil Domain.find_by_id(d.id)
  end
  
  def test_authorize_user
    post :authorize_ssh_user, {
      :organization=>{
      :id => 1,
      :username => 'ian',
      :password => 'testpass',
      :public_key => 'asdfuefij'}}
      
    assert_response :success
    assert @response.body =~ /<organization>/
    assert @response.body =~ /<public-key>.*<\/public-key>/
  end
  
  def test_authorize_user_error
    post :authorize_ssh_user, {
      :organization=>{
      :id => 1,
      :username => 'error',
      :password => 'testpass',
      :public_key => 'asdfuefij'}}
      
    assert_response :success
    assert @response.body =~ /<error>/
    assert @response.body =~ /<message>.*<\/message>/
  end
  
  def test_deauthorize_user
    post :deauthorize_ssh_user, {
      :organization=>{
      :id => 1,
      :username => 'ian',
      :password => 'testpass',
      :public_key => 'asdfuefij'}}
      
    assert_response :success
    assert @response.body =~ /<success/
  end
  
  def test_deauthorize_user_error
    post :deauthorize_ssh_user, {
      :organization=>{
      :id => 1,
      :username => 'error',
      :password => 'testpass',
      :public_key => 'asdfuefij'}}
      
    assert_response :success
    assert @response.body =~ /<error>/
    assert @response.body =~ /<message>.*<\/message>/
  end
end