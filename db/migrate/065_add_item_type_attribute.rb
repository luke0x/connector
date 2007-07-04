=begin #(fold)
Copyright 2004-2007 Joyent Inc.

Redistribution and/or modification of this code is governed
by either the GPLv2 or Joyent Commercial Software licenses.

Report issues and contribute at http://dev.joyent.com/

$Id$
=end #(end)

class AddItemTypeAttribute < ActiveRecord::Migration
  def self.up
    SmartGroupAttributeDescription.create({
    :smart_group_description_id=>1,
    :name => "Item Type",
    :attribute_name => "item_type"
    })
  end

  def self.down
    
  end
end
