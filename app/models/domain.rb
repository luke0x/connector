=begin #(fold)
Copyright 2004-2007 Joyent Inc.

Redistribution and/or modification of this code is governed
by either the GPLv2 or Joyent Commercial Software licenses.

Report issues and contribute at http://dev.joyent.com/

$Id$
=end #(end)

class Domain < ActiveRecord::Base
  validates_presence_of   :organization_id
  validates_presence_of   :web_domain
  validates_presence_of   :email_domain 
  validates_uniqueness_of :email_domain
  validates_format_of     :web_domain,   :with => /^([a-z0-9]+[a-z0-9\-]*[a-z0-9]+\.)+[a-z]{2,}$/i
  validates_format_of     :email_domain, :with => /^([a-z0-9]+[a-z0-9\-]*[a-z0-9]+\.)+[a-z]{2,}$/i
  
  belongs_to :organization
  
  before_save :transform_domains

  cattr_accessor :current

  def authenticate_user(username, password, sha1=false)
    return false if username.blank?
    return false if password.blank?
    return false unless user = organization.users.find_by_username(username)
    user.authenticate(password, sha1) ? user : false
  end
  
  # fetches the 
  def make_primary!
    return if primary?
    current_primary = self.organization.domains.find_by_primary(true)
    current_primary.toggle!(:primary)
    self.primary=true
    self.save!
  end

  private

    def transform_domains
      write_attribute(:web_domain, web_domain.downcase) unless web_domain.blank?
      write_attribute(:email_domain, email_domain.downcase) unless email_domain.blank?
    end
end