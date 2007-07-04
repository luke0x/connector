=begin #(fold)
Copyright 2004-2007 Joyent Inc.

Redistribution and/or modification of this code is governed
by either the GPLv2 or Joyent Commercial Software licenses.

Report issues and contribute at http://dev.joyent.com/

$Id$
=end #(end)

# Change all 'Group' subscribaable_type's to correct 'ContactList'

class ChangeGroupSubscribableType < ActiveRecord::Migration
  def self.up
    Subscription.find_all_by_subscribable_type('Group').each do |s|
      s.update_attribute(:subscribable_type, 'ContactList')
    end
  end

  def self.down
      Subscription.find_all_by_subscribable_type('ContactList').each do |s|
        s.update_attribute(:subscribable_type, 'Group')
      end
  end
end
