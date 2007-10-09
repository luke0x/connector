=begin #(fold)
++
Copyright 2004-2007 Joyent Inc.

Redistribution and/or modification of this code is 
governed by the GPLv2.

Report issues and contribute at http://dev.joyent.com/

$Id$
--
=end #(end)

class GuestPath < ActiveRecord::Base
  belongs_to :owner, :class_name => "User", :foreign_key => "user_id"
  belongs_to :guest, :class_name => "User", :foreign_key => "guest_id"
end
