=begin #(fold)
++
Copyright 2004-2007 Joyent Inc.

Redistribution and/or modification of this code is 
governed by the GPLv2.

Report issues and contribute at http://dev.joyent.com/

$Id$
--
=end #(end)

class ClearLoginTokens < ActiveRecord::Migration
  def self.up
    # the way this works has changed
    LoginToken.destroy_all
  end

  def self.down
    LoginToken.destroy_all
  end
end
