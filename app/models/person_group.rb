=begin #(fold)
++
Copyright 2004-2007 Joyent Inc.

Redistribution and/or modification of this code is 
governed by the GPLv2.

Report issues and contribute at http://dev.joyent.com/

$Id$
--
=end #(end)

class PersonGroup < ActiveRecord::Base
  include JoyentGroup  
  validates_presence_of :name
  
  has_many   :person_group_memberships, :dependent => :destroy
  has_many   :people,                   :through => :person_group_memberships

  def children
    []
  end
  
  def parent
    nil
  end
  
  def descendent?(group)
    false
  end
  
  def rename!(name)
    self.name = name
    self.save
  end
  
  # TOTAL HAX
  def url_id
    "pg#{self.id}"
  end
  
  # people whom can be added to this person group
  # TODO: add ordering
  def people_left(force_reload = false)
    if force_reload or @people_left.nil?
      organization_people = organization.users.find(:all, :include => [:person], :scope => :read).collect(&:person)
      @people_left = organization_people + owner.contact_list.people(true) - people(true)
    end
    @people_left
  end

  def cascade_permissions
    # TODO
  end
  
  # turns pg17 into 17
  def self.param_to_id(person_group_id)
    person_group_id.sub(/^pg/, '')
  end
  
  # users with membership to this group
  def users(force_reload = false)
    if force_reload or @users.nil?
      @users = people.find_all{ |person| person.user?  }.collect(&:user)
    end
    @users
  end
  
end
