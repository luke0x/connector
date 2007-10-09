=begin #(fold)
++
Copyright 2004-2007 Joyent Inc.

Redistribution and/or modification of this code is 
governed by the GPLv2.

Report issues and contribute at http://dev.joyent.com/

$Id$
--
=end #(end)
class ChangePeopleCacheSortSettings < ActiveRecord::Migration
  def self.up
    UserOption.find(:all, :conditions => ["user_options.key = 'People Sort Field' AND value = 'primary_email'"]).each do |user_option|
      user_option.update_attribute(:value, 'primary_email_cache')
    end
    UserOption.find(:all, :conditions => ["user_options.key = 'People Sort Field' AND value = 'primary_phone'"]).each do |user_option|
      user_option.update_attribute(:value, 'primary_email_cache')
    end
  end

  def self.down
    UserOption.find(:all, :conditions => ["user_options.key = 'People Sort Field' AND value = 'primary_email_cache'"]).each do |user_option|
      user_option.update_attribute(:value, 'primary_email')
    end
    UserOption.find(:all, :conditions => ["user_options.key = 'People Sort Field' AND value = 'primary_phone_cache'"]).each do |user_option|
      user_option.update_attribute(:value, 'primary_email')
    end
  end
end
