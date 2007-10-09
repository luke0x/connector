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

# dig my haxing
module LDAP
end

class ProductionLdapSystemTest < Test::Unit::TestCase
  fixtures all_fixtures

  def setup
    @system = ProductionLdapSystem.new(JoyentConfig.ldap_host, 'user', 'pass', 'dc=joyent,dc=com')
  end
  
  def test_user_dn
    assert_equal "ou=users,o=joyent.joyent.com,dc=joyent,dc=com", 
                 @system.user_dn(organizations(:joyent))
  end
  
  def test_contact_dn
    assert_equal "ou=contacts,o=joyent.joyent.com,dc=joyent,dc=com",
                 @system.contact_dn(organizations(:joyent))
  end
  
  def test_person_to_ldap
    assert_matches_fixture 'ian-person', @system.person_to_ldap(people(:ian))
  end

  def test_user_to_ldap
    assert_matches_fixture 'ian-user', @system.user_to_ldap(users(:ian))
  end

  def test_base_dn_for_person
    assert_equal "dbid=1,ou=contacts,o=joyent.joyent.com,dc=joyent,dc=com", 
                 @system.base_dn_for_person(people(:ian))
  end
  
  def test_base_dn_for_user
    assert_equal "uid=ian@joyent.joyent.com,ou=users,o=joyent.joyent.com,dc=joyent,dc=com",
                 @system.base_dn_for_user(users(:ian))
  end
  
  def test_person_to_ldap_without_addresses_or_phone
    assert_matches_fixture 'user_with_restrictions-person',
                 @system.person_to_ldap(people(:user_with_restrictions))
  end
  
  
  def test_person_to_ldap_with_address_no_phone
    assert_matches_fixture 'notuser-person', @system.person_to_ldap(people(:notuser))
  end
  
  def test_person_to_ldap_without_address_with_phone
    assert_matches_fixture 'jason-person', @system.person_to_ldap(people(:jason))
  end

  def test_base_hash
    h = {"objectClass"=>["top", "dcObject", "organization", "joyentOrganization"], "o"=>["joyent.joyent.com"], "description"=>["Root for Joyent"], "dc"=>["joyent"], "aliasDomain"=>["joyent.joyent.com", "joyent.net", "koz.dev.joyent.com"]}
    assert_equal h, @system.base_hash(organizations(:joyent))
  end  

  def test_users_hash
    h = {"description"=>["Users for Joyent"], "ou"=>["users"], "objectClass"=>["top", "organizationalUnit"]}
    assert_equal h, @system.users_hash(organizations(:joyent))
  end
  
  def test_contacts_hash
    h = {"description"=>["Contacts for Joyent"], "ou"=>["contacts"], "objectClass"=>["top", "organizationalUnit"]}
    assert_equal h, @system.contacts_hash(organizations(:joyent))
  end

  def assert_matches_fixture(name, object)
    assert_equal ldap_fixture(name), object
  end
end