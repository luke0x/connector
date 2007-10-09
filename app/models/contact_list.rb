=begin #(fold)
++
Copyright 2004-2007 Joyent Inc.

Redistribution and/or modification of this code is 
governed by the GPLv2.

Report issues and contribute at http://dev.joyent.com/

$Id$
--
=end #(end)

class ContactList < ActiveRecord::Base
  include JoyentGroup

  has_many :people,  :dependent => :destroy

  def name
    'Contacts'
  end

  def children
    []
  end
  
  def descendent?(group)
    false
  end

  def build_person(attrs)
    associations = {:user_id => owner.id, :organization_id => owner.organization.id, :contact_list_id => id}
    a = Person.new attrs.merge(associations)
  end

  def cascade_permissions
    users = permissions.collect(&:user)
    people.each{|p| p.restrict_to!(users)}
  end
end