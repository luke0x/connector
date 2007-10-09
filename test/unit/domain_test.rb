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

class DomainTest < Test::Unit::TestCase
  fixtures :users, :organizations, :domains
  include CRUDTest
  
  crud_data 'organization_id' => 1,
            'web_domain'      => 'bar.com',
            'email_domain'    => 'foo.com',
            'primary'         => true
  

  crud_required 'organization_id', 'web_domain', 'email_domain'

  def test_lowercase_transformation
    @test_data['email_domain'] = 'FOO.COM'
    @test_data['web_domain']   = 'BAR.COM'
    
    dom = assert_create
    assert_equal 'foo.com', dom.email_domain
    assert_equal 'bar.com', dom.web_domain
  end
  
  def test_invalid_domain
    @test_data['web_domain'] = '#@%$23foo.com'
    assert_no_create
  end
  
  def test_authenticate_user
    u = domains(:joyent).authenticate_user('ian', 'testpass')
    assert u.is_a?(User)
    assert_equal users(:ian).id, u.id
  end
  
  def test_authenticate_user_wrong_password
    assert !domains(:joyent).authenticate_user('ian', 'foo')
  end
  
  def test_authenticate_user_no_user
    assert !domains(:joyent).authenticate_user('stephen', 'foo')
  end
  
  def test_authenticate_user_wrong_domain
    assert !domains(:textdrive).authenticate_user('ian', 'testpass')
  end
  
  def test_make_primary_on_primary
    domains(:joyent).make_primary!
    assert_equal domains(:joyent), organizations(:joyent).primary_domain
  end
  
  def test_make_primary_on_non_primary
    domains(:joyent_net).make_primary!
    assert_equal domains(:joyent_net), organizations(:joyent).primary_domain
    assert !domains(:joyent).primary?
  end
end
