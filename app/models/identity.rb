=begin #(fold)
++
Copyright 2004-2007 Joyent Inc.

Redistribution and/or modification of this code is 
governed by the GPLv2.

Report issues and contribute at http://dev.joyent.com/

$Id$
--
=end #(end)

class Identity < ActiveRecord::Base
  has_many :users, :include => [:organization], :order => "organizations.name, users.username"
end