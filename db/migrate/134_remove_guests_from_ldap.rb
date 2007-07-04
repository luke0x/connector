=begin #(fold)
Copyright 2004-2007 Joyent Inc.

Redistribution and/or modification of this code is governed
by either the GPLv2 or Joyent Commercial Software licenses.

Report issues and contribute at http://dev.joyent.com/

$Id$
=end #(end)

class RemoveGuestsFromLdap < ActiveRecord::Migration
  def self.up
    User.find(:all, :conditions => ["guest = ?", true]).each do |guest|
      Person.ldap_system.ldap_execute do |ldap|
        ldap.delete(Person.ldap_system.base_dn_for_user(guest)) if Person.ldap_system.user_in_ldap?(guest)
      end
    end
  end

  def self.down
    # I don't want to reverse this one (which would be adding all the guests into ldap...not hard)
    # because then they would never get updated/removed/etc because the code won't ever
    # touch them again
  end
end
