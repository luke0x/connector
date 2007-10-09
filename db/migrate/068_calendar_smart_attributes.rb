=begin #(fold)
++
Copyright 2004-2007 Joyent Inc.

Redistribution and/or modification of this code is 
governed by the GPLv2.

Report issues and contribute at http://dev.joyent.com/

$Id$
--
=end #(end)

class CalendarSmartAttributes < ActiveRecord::Migration
  def self.up
    SmartGroupAttributeDescription.create({
       "name"=>"Repeat Type", "attribute_name"=>"recurrence_name", "smart_group_description_id"=>4
    })
    SmartGroupAttributeDescription.create({
       "name"=>"Event Name", "attribute_name"=>"name", "smart_group_description_id"=>4
    })
  end

  def self.down
  end
end
