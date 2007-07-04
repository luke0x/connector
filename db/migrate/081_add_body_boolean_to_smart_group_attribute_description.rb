=begin #(fold)
Copyright 2004-2007 Joyent Inc.

Redistribution and/or modification of this code is governed
by either the GPLv2 or Joyent Commercial Software licenses.

Report issues and contribute at http://dev.joyent.com/

$Id$
=end #(end)

class AddBodyBooleanToSmartGroupAttributeDescription < ActiveRecord::Migration
  def self.up
    add_column :smart_group_attribute_descriptions, :body, :boolean
    SmartGroupDescription.find(:all).each do |sgd|
      sgd.smart_group_attribute_descriptions.create(:name=>"Any Special Condition", :body=>true)
    end
  end

  def self.down
    remove_column :smart_group_attribute_descriptions, :body
  end
end
