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

class MailAliasTest < Test::Unit::TestCase
  fixtures all_fixtures
  include CRUDTest

  crud_data 'name'            => 'support',
            'organization_id' => 1
  crud_required 'name', 'organization_id'

  def setup
    User.current = users(:ian)
    Organization.current = User.current.organization
  end

  def test_create_with_username
    m = MailAlias.create(:name => Organization.current.users.first.username, :organization_id => Organization.current.id)
    assert_equal 1, m.errors.length
  end

  def test_mail_aliases_exist
    assert_equal 2, users(:ian).mail_aliases.size
    assert_equal 1, users(:peter).mail_aliases.size 
    assert_equal 1, mail_aliases(:info).users.size
    assert_equal 2, mail_aliases(:www).users.size
  end
  
  def test_adding_new_alias
    m = MailAlias.create(:organization_id => 1, :name => 'help')
    
    users(:ian).mail_alias_memberships.create(:mail_alias_id => m)
    assert_equal 3, User.find(users(:ian).id).mail_aliases.size
  end
  
  def test_system_email
    assert_equal "www@joyent.joyent.com", mail_aliases(:www).system_email_address
  end
  
  def test_other_emails
    assert_equal 3, mail_aliases(:www).email_addresses.size
    assert mail_aliases(:www).email_addresses.include?("www@joyent.net")
    assert mail_aliases(:www).email_addresses.include?("www@joyent.joyent.com")
    assert mail_aliases(:www).email_addresses.include?("www@koz.dev.joyent.com")    
  end
end
