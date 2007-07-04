=begin #(fold)
Copyright 2004-2007 Joyent Inc.

Redistribution and/or modification of this code is governed
by either the GPLv2 or Joyent Commercial Software licenses.

Report issues and contribute at http://dev.joyent.com/

$Id$
=end #(end)

class DeleteOrphanedInvitations < ActiveRecord::Migration
  def self.up
    Invitation.find(:all).each{|invite| invite.destroy unless invite.event}
  end

  def self.down
  end
end
