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

class AuthKeyTest < Test::Unit::TestCase
  include CRUDTest
  fixtures :organizations, :users, :auth_keys

  crud_data 'key'             => '123557567SDFJGSDF',
            'organization_id' => 1,
            'user_id'         => 1

  crud_required 'key', 'organization_id', 'user_id'

  def test_generate_good
    assert AuthKey.generate(organizations(:joyent), users(:ian), users(:ian).plaintext_password)
  end
  
  def test_generate_bad
    assert !AuthKey.generate(organizations(:joyent), users(:ian), 'notgoodpassword')
  end
  
  def test_verify_good
    assert AuthKey.verify(auth_keys(:joyent).key, organizations(:joyent))
  end
  
  def test_verify_bad_key
    assert !AuthKey.verify('blargh', organizations(:joyent))
  end
  
  def test_verify_bad_org
    assert !AuthKey.verify(auth_keys(:joyent).key, organizations(:textdrive))
  end
  
  def test_verify_expired
    assert !AuthKey.verify(auth_keys(:expired).key, organizations(:joyent))
  end
end
