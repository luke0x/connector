=begin #(fold)
++
Copyright 2004-2007 Joyent Inc.

Redistribution and/or modification of this code is 
governed by the GPLv2.

Report issues and contribute at http://dev.joyent.com/

$Id$
--
=end #(end)

class AssociateOrphanedPeople < ActiveRecord::Migration
  def self.up  
    orphans = Person.find(:all).select{|person| !person.user? && !person.contact_list}
    
    orphans.each do |person|   
      if !person.owner.contact_list 
        person.owner.contact_list = ContactList.create
        person.save
      end
      person.contact_list = person.owner.contact_list
      person.save
    end
  end

  def self.down
  end
end
