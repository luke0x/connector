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

class LdapObserversTest < Test::Unit::TestCase
  fixtures all_fixtures
  
  def setup    
    @test_ldap_system = TestLdapSystem.new
    Person.ldap_system = @test_ldap_system
  end
  
  def test_updated_user_without_restrictions_is_written
    p = people(:notuser)
    p.middle_name= "luser"
    p.save!

    assert @test_ldap_system.written_people.include?(p)
  end

  def test_secret_person_is_removed
    p = people(:secret_person)
    p.middle_name= "luser2"
    p.save!
    
    assert @test_ldap_system.nuked_people.include?(p)
  end
    
  def test_user_gets_removed_when_destroyed
    u = users(:user_with_restrictions)
    u.destroy
    
    assert @test_ldap_system.nuked_users.include?(u)
  end
  
  def test_promoting_user_writes_person
    p = people(:notuser)
    u = p.create_user({:username=>"notuser", :password=>"asdfasdfasdf", :organization => p.organization, :identity => Identity.create})

    assert @test_ldap_system.written_users.include?(u)
  end
  
  def test_destroying_organization_removes_org
    o = organizations(:joyent)
    # o.deactivate!
    # o.destroy
    # 
    # assert @test_ldap_system.nuked_organizations.include?(o)
  end
  
end