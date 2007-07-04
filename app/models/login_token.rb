=begin #(fold)
Copyright 2004-2007 Joyent Inc.

Redistribution and/or modification of this code is governed
by either the GPLv2 or Joyent Commercial Software licenses.

Report issues and contribute at http://dev.joyent.com/

$Id$
=end #(end)

class LoginToken < ActiveRecord::Base
  validates_presence_of :user_id

  belongs_to :user
  
  delegate :organization, :to => :user

  cattr_accessor :current 
  
  def before_create
    self.value = Digest::MD5.hexdigest("#{JoyentConfig.login_token_new_salt}#{Time.now.to_s}$$")
  end
  
  def self.find_for_sso(value)
    self.find(:first, :conditions=>["value = ? and updated_at > ? ", value, 5.minutes.ago])
  end

  def self.find_for_cookie(value)
    self.find(:first, :conditions=>["value = ? and created_at > ? ", value, 14.days.ago])
  end
end