=begin #(fold)
++
Copyright 2004-2007 Joyent Inc.

Redistribution and/or modification of this code is 
governed by the GPLv2.

Report issues and contribute at http://dev.joyent.com/

$Id$
--
=end #(end)

class Calling < ActiveRecord::Base
  belongs_to :call
  belongs_to :callee, :class_name => "Person", :foreign_key => "callee_id"
end
