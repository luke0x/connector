=begin #(fold)
++
Copyright 2004-2007 Joyent Inc.

Redistribution and/or modification of this code is 
governed by the GPLv2.

Report issues and contribute at http://dev.joyent.com/

$Id$
--
=end #(end)

module JoyentItem
  def self.included(base)
    base.send :include, Commentable
    base.send :include, Notifiable
    base.send :include, RestrictedFind
    base.send :include, Securable
    base.send :include, Taggable

    base.validates_presence_of :organization_id
    base.validates_presence_of :user_id

    base.belongs_to :organization
    base.belongs_to :owner, :class_name => 'User', :foreign_key => 'user_id'
  end
end