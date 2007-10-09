=begin #(fold)
++
Copyright 2004-2007 Joyent Inc.

Redistribution and/or modification of this code is 
governed by the GPLv2.

Report issues and contribute at http://dev.joyent.com/

$Id$
--
=end #(end)

class UserOption < ActiveRecord::Base
  validates_presence_of :key
  validates_presence_of :value
  validates_uniqueness_of :key, :scope => 'user_id'

  belongs_to :user
end