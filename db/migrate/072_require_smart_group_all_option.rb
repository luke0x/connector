=begin #(fold)
Copyright 2004-2007 Joyent Inc.

Redistribution and/or modification of this code is governed
by either the GPLv2 or Joyent Commercial Software licenses.

Report issues and contribute at http://dev.joyent.com/

$Id$
=end #(end)

class RequireSmartGroupAllOption < ActiveRecord::Migration
  def self.up  
    SmartGroup.find(:all).select{|smart_group| smart_group.accept_any?}.each do |smart_group|
      smart_group.accept_any = false
      smart_group.save
    end
  end

  def self.down
  end
end