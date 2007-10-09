=begin #(fold)
++
Copyright 2004-2007 Joyent Inc.

Redistribution and/or modification of this code is 
governed by the GPLv2.

Report issues and contribute at http://dev.joyent.com/

$Id$
--
=end #(end)


class CleanupOrphanedPolymorphicInfo < ActiveRecord::Migration
  def self.up
    Notification.find(:all).select {|n| n.item.nil?}.map(&:destroy)
    Permission.find(:all).select   {|p| p.item.nil?}.map(&:destroy)
    Comment.find(:all).select      {|c| c.commentable.nil?}.map(&:destroy)
    Tagging.find(:all).select      {|t| t.taggable.nil?}.map(&:destroy)
  end

  def self.down
  end
end
