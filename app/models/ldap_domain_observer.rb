=begin #(fold)
Copyright 2004-2007 Joyent Inc.

Redistribution and/or modification of this code is governed
by either the GPLv2 or Joyent Commercial Software licenses.

Report issues and contribute at http://dev.joyent.com/

$Id$
=end #(end)

class LdapDomainObserver < ActiveRecord::Observer
  observe Domain
  
  def after_save(domain)
    Person.ldap_system.update_organization(domain.organization) unless domain.system_domain
  end
  
  def after_destroy(domain)
    Person.ldap_system.update_organization(domain.organization) unless domain.system_domain
  end
end