=begin #(fold)
Copyright 2004-2007 Joyent Inc.

Redistribution and/or modification of this code is governed
by either the GPLv2 or Joyent Commercial Software licenses.

Report issues and contribute at http://dev.joyent.com/

$Id$
=end #(end)

class Subscription < ActiveRecord::Base
  belongs_to :organization
  belongs_to :owner,        :class_name => 'User', :foreign_key => 'user_id'
  belongs_to :subscribable, :polymorphic => true

  validates_presence_of :organization_id
  validates_presence_of :user_id
  validates_presence_of :subscribable_id
  validates_presence_of :subscribable_type
  
  def subscribable_type=(type)
    write_attribute(:subscribable_type, type.gsub(' ', ''))
  end
  
  def self.remove_by_owner(user, owner)
    user.subscriptions.each do |sub|
      Subscription.delete(sub.id) if sub.subscribable.owner == owner
    end
  end
  
  def self.find_by_type(group)
    find(:all, :conditions => ['organizations.active = ? AND subscribable_type = ?', true, group], :include => :organization)
  end
  
end