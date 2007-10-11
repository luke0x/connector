=begin #(fold)
++
Copyright 2004-2007 Joyent Inc.

Redistribution and/or modification of this code is 
governed by the GPLv2.

Report issues and contribute at http://dev.joyent.com/

$Id$
--
=end #(end)

class MailAlias < ActiveRecord::Base
  belongs_to :organization
  
  has_many   :mail_alias_memberships, :dependent => :destroy
  has_many   :users, :through => :mail_alias_memberships
  
  validates_presence_of   :organization_id
  validates_presence_of   :name
  validates_format_of     :name, :with => /^[a-z]([_.]?[a-z0-9]+)*$/
  validates_length_of     :name, :maximum => 50
  validates_uniqueness_of :name, :scope => 'organization_id'
  
  def system_email_address
    self.name + '@' + self.organization.system_domain.email_domain  
  end
  
  def email_addresses
    self.organization.domains.collect{|domain| self.name + '@' + domain.email_domain}
  end
  
  def add_user(user)
    raise "Not a user" if user.blank? or !user.is_a?(User)
    raise "User must belong to this org" if user.organization != organization
    
    mail_alias_memberships.create(:user_id => user.id)
  end
  
  def membership_for_user(user)
    raise "Not a user" if user.blank? or !user.is_a?(User)

    mail_alias_memberships.detect{|mam| mam.user == user}
  end
  
  protected
  
    def validate
      errors.add(:name, "The name can not be the same as a username.") if Organization.current.users.find_by_username(self.name)
    end
end
