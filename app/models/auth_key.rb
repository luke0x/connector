=begin #(fold)
Copyright 2004-2007 Joyent Inc.

Redistribution and/or modification of this code is governed
by either the GPLv2 or Joyent Commercial Software licenses.

Report issues and contribute at http://dev.joyent.com/

$Id$
=end #(end)

class AuthKey < ActiveRecord::Base
  validates_presence_of :key
  validates_presence_of :organization_id
  validates_presence_of :user_id
  
  belongs_to :organization
  belongs_to :user
  
  def self.generate(organization, user, password)
    if organization.users.include?(user) && user.plaintext_password == password
      AuthKey.create :organization => organization, :user => user, :key => UUID.create.to_s
    else
      false
    end
  end
  
  def self.verify(key, organization)
    key = find_by_key_and_organization_id(key, organization.id)
    if key && (Time.now.utc - key.created_at) < 5.minutes
      key
    else
      false
    end
  end
end
