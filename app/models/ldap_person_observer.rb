=begin #(fold)
++
Copyright 2004-2007 Joyent Inc.

Redistribution and/or modification of this code is 
governed by the GPLv2.

Report issues and contribute at http://dev.joyent.com/

$Id$
--
=end #(end)

class LdapPersonObserver < ActiveRecord::Observer
  observe Person
  
  def after_save(person)
    if person.exportable?
      person.write_to_ldap!
    else
      person.remove_from_ldap!
    end
  end
  
  def after_destroy(person)
    person.remove_from_ldap!
  end
end