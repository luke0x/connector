=begin #(fold)
++
Copyright 2004-2007 Joyent Inc.

Redistribution and/or modification of this code is 
governed by the GPLv2.

Report issues and contribute at http://dev.joyent.com/

$Id$
--
=end #(end)

class Permission < ActiveRecord::Base
  validates_presence_of :user_id
  validates_presence_of :item_id
  validates_presence_of :item_type
  
  belongs_to :user
  belongs_to :item, :polymorphic => true
end