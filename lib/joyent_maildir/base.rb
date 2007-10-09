=begin #(fold)
++
Copyright 2004-2007 Joyent Inc.

Redistribution and/or modification of this code is 
governed by the GPLv2.

Report issues and contribute at http://dev.joyent.com/

$Id$
--
=end #(end)

require File.dirname(__FILE__) + '/maildir_worker'
require File.dirname(__FILE__) + '/mock_maildir_worker'

module JoyentMaildir
  class Base
    def self.connection
      JoyentMaildir::MaildirWorker.new
    end
    
    def self.remove_user(user)
      # FIXME Implement
      return unless user.organization.system_domain
    end

    def self.remove_organization(organization)
      # FIXME Implement
      return unless organization.system_domain
    end
  end
end
