=begin #(fold)
++
Copyright 2004-2007 Joyent Inc.

Redistribution and/or modification of this code is 
governed by the GPLv2.

Report issues and contribute at http://dev.joyent.com/

$Id$
--
=end #(end)

module RestrictedFind
  def self.included(base)
    base.extend ClassMethods
  end
  
  module Scopes
    # makes sure that the item's owner is in the current org
    def self.org_scope(user)
      {:find =>
        {:conditions => ['organizations.id = ?', user.organization.id],
         :include => [{:owner => :organization}]}
      }
    end

    # makes sure the item's org is the user's org and the use has item permissions 
    # uses 'hax_permissions' to stop monkeying with permissions see joyent_file_test.rb 
    # for more info
    def self.restrict_scope(user)
      {:find =>
        {:conditions => ['(organizations.id = ? and (permissions.user_id IS NULL OR permissions.user_id = ?))', user.organization.id, user.id],
         :include    => [{:owner => :organization}, :hax_permissions]}
      }
    end
  end
  
  module ClassMethods
    def restricted_find(*args)
      raise "No Current User" if User.current.blank?
      self.with_scope(Scopes::restrict_scope(User.current)) do
        self.find(*args)
      end
    end
    
    def restricted_count(*args)
      raise "No Current User" if User.current.blank?
      self.with_scope(Scopes::restrict_scope(User.current)) do
        self.count(*args)
      end
    end
  end
end