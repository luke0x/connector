=begin #(fold)
Copyright 2004-2007 Joyent Inc.

Redistribution and/or modification of this code is governed
by either the GPLv2 or Joyent Commercial Software licenses.

Report issues and contribute at http://dev.joyent.com/

$Id$
=end #(end)

class LdapOrganizationObserver < ActiveRecord::Observer
  observe Organization
  
  def after_update(organization)
    Person.ldap_system.update_organization(organization)

    # This is particulary important if the org is deactivated
    organization.users.each do |user|
      Person.ldap_system.write_user(user)
    end
  end
  
  def after_destroy(organization)
    Person.ldap_system.remove_organization(organization)
  end
end