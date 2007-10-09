=begin #(fold)
++
Copyright 2004-2007 Joyent Inc.

Redistribution and/or modification of this code is 
governed by the GPLv2.

Report issues and contribute at http://dev.joyent.com/

$Id$
--
=end #(end)

class ListFolder < ActiveRecord::Base
  include JoyentGroup
  
  validates_presence_of :name

  has_many :lists, :dependent => :destroy

  acts_as_tree :order => 'LOWER(list_folders.name)'

  def self.class_humanize; 'Folder'; end
  def class_humanize; 'Folder'; end

  # is group a descendent of me?
  def descendent?(group)
    return false if group.blank?
    return false if children.blank?
    return true if children.include?(group)
    children.each do |child|
      return true if child.descendent?(group)
    end
    false
  end

  def rename!(name)
    return false if self.parent.blank?

    self.name = name
    self.save
  end

  def reparent!(new_parent)
    return if self.parent.blank?
    return if new_parent == self
    return if descendent?(new_parent)

    self.parent = new_parent
    self.save
  end
  
  protected
  
    def validate
      return false unless owner
      
      root_list_folder = owner.list_folders.find(:first, :conditions => ["list_folders.name = 'Lists' AND list_folders.parent_id IS NULL"])
      if root_list_folder && self.parent_id.blank? && self.id != root_list_folder.id
        errors.add(nil, "Only one root list folder can exist")
      end
    end
  
end