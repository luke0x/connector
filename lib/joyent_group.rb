=begin #(fold)
Copyright 2004-2007 Joyent Inc.

Redistribution and/or modification of this code is governed
by either the GPLv2 or Joyent Commercial Software licenses.

Report issues and contribute at http://dev.joyent.com/

$Id$
=end #(end)

module JoyentGroup
  def self.included(base)
    base.send :include, RestrictedFind
    base.send :include, Securable
    base.send :include, Subscribable

    base.validates_presence_of :user_id
    base.validates_presence_of :organization_id

    base.belongs_to :owner, :class_name => 'User', :foreign_key => 'user_id'
    base.belongs_to :organization
    base.has_many :reports, :dependent => :destroy, :as => :reportable
  end
end