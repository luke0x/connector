=begin #(fold)
Copyright 2004-2007 Joyent Inc.

Redistribution and/or modification of this code is governed
by either the GPLv2 or Joyent Commercial Software licenses.

Report issues and contribute at http://dev.joyent.com/

$Id$
=end #(end)

module Securable
  def self.included(base)
    base.has_many :permissions, :as => :item, :dependent => :destroy
    base.has_many :restricted_to_users, :through=>:permissions, :source=>:user
    # this nastiness is so RestrictedFind doesn't break
    base.has_many :hax_permissions, :as => :item, :class_name=>"Permission"
  end

  def restrict_to!(users)
    self.permissions.clear
    users.each do |user|
      self.permissions.create(:user_id=>user.id)
    end
    cleanup_permissions
  end

  def make_public!
    restrict_to!([])
  end
  
  def make_private!
    restrict_to!([self.owner])
  end
  
  def add_permission(user)
    # ignore repeat calls
    return if permission_for(user)
    self.permissions.create(:user_id => user.id)
    cleanup_permissions
  end
  
  def remove_permission(user)
    if self.permissions.length == 0
      (user.organization.users.reject{|u| u.guest?} - [user]).each do |user|
        self.permissions.create(:user_id => user.id)
      end
      self.reload
      cleanup_permissions
    elsif perm = permission_for(user)
      perm.destroy
      self.reload
      cleanup_permissions
    end
  end
  
  def permission_for(user)
    self.permissions.detect {|p| p.user_id == user.id}
  end

  def cascade_permissions
    # implemented by group classes
  end
  
  def cleanup_permissions
    ensure_owner_has_permission
    ensure_viewer_has_permission
    ensure_public_is_empty
    cascade_permissions
    remove_obsolete_associations
    save
  end

  # be careful this doesn't get called recursively
  def ensure_owner_has_permission
    return if self.permissions.empty?
    return if self.permission_for(self.owner)

    self.permissions.create(:user_id => self.owner.id)
  end

  # the viewer == the person changing permissions on an item they don't own
  def ensure_viewer_has_permission
    return if self.permissions.empty?
    return if self.permission_for(User.current)
    
    self.permissions.create(:user_id => User.current.id)
  end

  # make permissions implicit if all users have explicit permission
  def ensure_public_is_empty
    return if self.permissions.empty?
    return unless self.permissions.length == self.organization.users_and_admins.length
    
    self.permissions.clear
  end

  # remove notifications when their owner no longer has access to the item
  def remove_obsolete_associations
    user_ids = self.permissions.map(&:user_id)
    return if user_ids.blank?

    Notification.destroy_all([ "item_id = ? AND item_type = ? AND notifiee_id NOT IN (?)", id, self.class.to_s, user_ids ])
  end

  def users_with_permissions
    if self.permissions.empty?
      self.organization.users
    else
      self.restricted_to_users
    end
  end
  
  def restrictable_to_users
    User.current.organization.users.reject{|u| u.guest?} - restricted_to_users
  end  
  
  def public?
    self.permissions.empty? || (self.permissions.length == self.organization.users.length)
  end
  
  def restricted?
    (self.permissions.length > 0) && (self.permissions.length < self.organization.users.length)
  end 
  
  def private?
    self.permissions.length == 1 and self.permissions.first.user == self.permissions.first.item.owner
  end
end