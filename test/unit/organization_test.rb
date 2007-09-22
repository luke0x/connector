=begin #(fold)
Copyright 2004-2007 Joyent Inc.

Redistribution and/or modification of this code is governed
by either the GPLv2 or Joyent Commercial Software licenses.

Report issues and contribute at http://dev.joyent.com/

$Id$
=end #(end)

require File.dirname(__FILE__) + '/../test_helper'

class OrganizationTest < Test::Unit::TestCase
  fixtures :organizations, :domains, :people, :users, :quotas, :email_addresses
  include CRUDTest
  
  crud_data 'name'           => 'Joyent',
            'active'         => false

  crud_required 'name'
  
  def test_system_domain
    assert_equal domains(:joyent), organizations(:joyent).system_domain
  end 
  
  def test_find_contact_with_email
    assert_nil organizations(:joyent).find_contact_with_email('bogus@joyent.com')
    assert     organizations(:joyent).find_contact_with_email(email_addresses(:ian_at_joyent).email_address) 
  end
  
  def test_primary_domain
    assert_equal domains(:joyent), organizations(:joyent).primary_domain
  end
  
  def test_search
    o = organizations(:joyent)
    User.current = users(:ian)
    Organization.current= o
    
    assert_equal [], o.search("pants")
  end
  
  def test_total_disk
    assert_equal 26251, organizations(:joyent).total_disk_usage
  end  
  
  def test_can_add_user
    o = organizations(:joyent)
    assert o.can_add_user?
    q = o.quota
    q.users=1
    q.save!
    o.reload
    assert !o.can_add_user?
  end
  
  def test_all_users
    assert_equal [1,2,5,6,7], organizations(:joyent).users.map(&:id).sort
    assert_equal [1,2,5,6,7], (organizations(:joyent).users_and_admins.map(&:id) + organizations(:joyent).guests.map(&:id)).sort
  end
  
  def test_all_users_and_admins
    assert_equal [1,2,5,7], organizations(:joyent).users_and_admins.map(&:id).sort
  end
  
  def test_all_guests
    assert_equal [6], organizations(:joyent).guests.map(&:id).sort
  end
  
  def test_setup
    o = Organization.setup("Koz Inc.", "koz.koz.com", "koz", "testpass", "corel", "Michael", "Koziarski", 'koz@foo.com', 6, (5 * 1024), true)
    o = Organization.find(o.id) # hax to prevent shenanigans
    assert_equal "Koz Inc.", o.name
    d = o.system_domain
    
    assert_equal "koz.koz.com", d.email_domain
    assert_equal "koz.koz.com", d.web_domain 
    
    
    assert_equal 6, o.quota.users
    assert_equal 5, o.quota.gigabytes
    assert o.quota.custom_domains

    assert_equal 1, o.users.length
    assert u = d.authenticate_user("koz", "testpass")
    
    p = u.person
    assert_equal "Michael", p.first_name
    assert_equal "Koziarski", p.last_name
    assert u.admin?
    
    assert_equal o.affiliate, Affiliate.find(2)
  end

  def test_destroy_cascades
    oid = organizations(:joyent).id

    [Domain, Notification, Person, Quota, Tag, User].each do |c|
      assert c.find_all_by_organization_id(oid).length > 0
    end           
                                  
    organizations(:joyent).deactivate!
    organizations(:joyent).destroy

    [Domain, Notification, Person, Quota, Tag, User].each do |c|
      assert_equal 0, c.find_all_by_organization_id(oid).length
    end
  end

  def test_destroy_doesnt_go_overboard
    oid = organizations(:joyent).id
    all = []
    org = []

    [Domain, Notification, Person, Quota, Tag, User].each do |c|
      all << c.find(:all).length
      org << c.find_all_by_organization_id(oid).length
    end                           
    
    organizations(:joyent).deactivate!
    organizations(:joyent).destroy

    all.reverse!
    org.reverse!
    [Domain, Notification, Person, Quota, Tag, User].each do |c|
      assert_equal all.pop - org.pop, c.find(:all).length
    end
  end

  def test_activate_and_deactivate
    assert organizations(:joyent).active?
    organizations(:joyent).deactivate!

    assert ! organizations(:joyent).active?
    organizations(:joyent).activate!

    assert organizations(:joyent).active?
  end

end