=begin #(fold)
++
Copyright 2004-2007 Joyent Inc.

Redistribution and/or modification of this code is 
governed by the GPLv2.

Report issues and contribute at http://dev.joyent.com/

$Id$
--
=end #(end)

class CreateGroupEntriesInLdap < ActiveRecord::Migration
  def self.up
    Organization.find(:all).each do |org|
      Person.ldap_system.update_organization(org)
    end
  end

  def self.down
    Organization.find(:all).each do |org|
      Person.ldap_system.remove_organization_group(org)
    end
  end
end
