=begin #(fold)
++
Copyright 2004-2007 Joyent Inc.

Redistribution and/or modification of this code is 
governed by the GPLv2.

Report issues and contribute at http://dev.joyent.com/

$Id$
--
=end #(end)

class Call < ActiveRecord::Base
  belongs_to :caller,   :class_name => "User", :foreign_key => "caller_id"
  has_many   :callings, :dependent  => :destroy
  has_many   :callees,  :through    => :callings
  
  def successful?
    status_code > 0
  end
end
