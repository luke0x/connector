=begin #(fold)
Copyright 2004-2007 Joyent Inc.

Redistribution and/or modification of this code is governed
by either the GPLv2 or Joyent Commercial Software licenses.

Report issues and contribute at http://dev.joyent.com/

$Id$
=end #(end)

class CreateListsSmartGroupData < ActiveRecord::Migration
  def self.up
    sgd = SmartGroupDescription.create(:name => 'Lists', :item_type => 'List')
    SmartGroupAttributeDescription.create(:name => 'Item Type',      :attribute_name => 'item_type',  :smart_group_description_id => sgd.id, :body => false)
    SmartGroupAttributeDescription.create(:name => 'Owner Username', :attribute_name => 'owner_name', :smart_group_description_id => sgd.id, :body => false)
    SmartGroupAttributeDescription.create(:name => 'Any Condition',  :attribute_name => nil,          :smart_group_description_id => sgd.id, :body => true)
  end

  def self.down
    SmartGroupDescription.find_by_name('Lists').destroy
  end
end