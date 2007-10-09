=begin #(fold)
++
Copyright 2004-2007 Joyent Inc.

Redistribution and/or modification of this code is 
governed by the GPLv2.

Report issues and contribute at http://dev.joyent.com/

$Id$
--
=end #(end)

# Reversing migration 151 cause that table was never used.
class DropServicesTable < ActiveRecord::Migration
  def self.up
    drop_table :services
  end

  def self.down
    create_table :services do |t|
    end
  end
end
