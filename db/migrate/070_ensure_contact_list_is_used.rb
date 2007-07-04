=begin #(fold)
Copyright 2004-2007 Joyent Inc.

Redistribution and/or modification of this code is governed
by either the GPLv2 or Joyent Commercial Software licenses.

Report issues and contribute at http://dev.joyent.com/

$Id$
=end #(end)

class EnsureContactListIsUsed < ActiveRecord::Migration
  def self.up
    User.find(:all).each do |user|
      user.create_contact_list unless user.contact_list
    end
    Person.find(:all).each do |person|
      person.contact_list = person.user? ? nil : person.owner.contact_list
      person.save
    end
  end

  def self.down
  end
end