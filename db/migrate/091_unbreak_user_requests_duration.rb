=begin #(fold)
++
Copyright 2004-2007 Joyent Inc.

Redistribution and/or modification of this code is 
governed by the GPLv2.

Report issues and contribute at http://dev.joyent.com/

$Id$
--
=end #(end)

class UnbreakUserRequestsDuration < ActiveRecord::Migration
  def self.up
    transaction do
      execute "ALTER TABLE user_requests ALTER COLUMN duration TYPE float"
      execute "UPDATE user_requests set duration = duration*1000.0"
    end
  end

  def self.down 
    transaction do
      execute "ALTER TABLE user_requests ALTER COLUMN duration TYPE integer"
      execute "UPDATE user_requests set duration = duration/1000.0"
    end
  end
end
