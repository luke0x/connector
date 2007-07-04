=begin #(fold)
Copyright 2004-2007 Joyent Inc.

Redistribution and/or modification of this code is governed
by either the GPLv2 or Joyent Commercial Software licenses.

Report issues and contribute at http://dev.joyent.com/

$Id$
=end #(end)

class CreateBookmarkSmartGroupInfo < ActiveRecord::Migration
  def self.up
    sgd = SmartGroupDescription.create(:name => 'Bookmarks', :item_type => 'Bookmark')
    SmartGroupAttributeDescription.create(:name => 'Any Condition', :smart_group_description_id => sgd.id, :body => true)
    SmartGroupAttributeDescription.create(:name => 'Address', :attribute_name => 'uri', :smart_group_description_id => sgd.id, :body => false)
    SmartGroupAttributeDescription.create(:name => 'Title', :attribute_name => 'title', :smart_group_description_id => sgd.id, :body => false)
    SmartGroupAttributeDescription.create(:name => 'Notes', :attribute_name => 'notes', :smart_group_description_id => sgd.id, :body => false)
    SmartGroupAttributeDescription.create(:name => 'Owner Username', :attribute_name => 'owner_name', :smart_group_description_id => sgd.id, :body => false)
    sgd = SmartGroupDescription.find_by_name('Messages')
    SmartGroupAttributeDescription.create(:name => 'Status', :attribute_name => 'status', :smart_group_description_id => sgd.id, :body => false)
  end

  def self.down
    sgd = SmartGroupDescription.find_by_name('Bookmarks')
    SmartGroupAttributeDescription.find(:all, :conditions => ["smart_group_description_id = ?", sgd.id]).map(&:destroy)
    sgd.destroy
    sgd = SmartGroupDescription.find_by_name('Messages')
    SmartGroupAttributeDescription.find(:all, :conditions => ["smart_group_description_id = ? and name = ?", sgd.id, 'Status']).map(&:destroy)
  end
end