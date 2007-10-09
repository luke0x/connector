=begin #(fold)
++
Copyright 2004-2007 Joyent Inc.

Redistribution and/or modification of this code is 
governed by the GPLv2.

Report issues and contribute at http://dev.joyent.com/

$Id$
--
=end #(end)

class TestLdapSystem
  attr_accessor :nuked_people, :written_people, :nuked_users, :written_users, :nuked_organizations,
                :written_organizations
  def initialize
    @written_people        = []
    @nuked_people          = []
    @written_users         = []
    @nuked_users           = []
    @written_organizations = []
    @nuked_organizations   = []
  end
  
  def ldap_execute
  end
  
  def write_person(p)
    @written_people << p
  end
  
  def remove_person(p)
    @nuked_people << p
  end
  
  def write_user(u)
    @written_users << u
  end
  
  def remove_user(u)
    @nuked_users << u
  end
  
  def write_organization(o)
    @written_organizations << o
  end
  
  def remove_organization(o)
    @nuked_organizations << o
  end
  
  def update_organization(o)
  end
  
  def remove_organization_group(o)
  end
end