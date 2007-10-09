=begin #(fold)
++
Copyright 2004-2007 Joyent Inc.

Redistribution and/or modification of this code is 
governed by the GPLv2.

Report issues and contribute at http://dev.joyent.com/

$Id$
--
=end #(end)

class SystemAsAttributeNamesIsNonHot < ActiveRecord::Migration
  def self.up
    rename_column :domains, :system, :system_domain
  end

  def self.down
    rename_column :domains, :system_domain, :system
  end
end
