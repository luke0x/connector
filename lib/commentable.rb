=begin #(fold)
++
Copyright 2004-2007 Joyent Inc.

Redistribution and/or modification of this code is 
governed by the GPLv2.

Report issues and contribute at http://dev.joyent.com/

$Id$
--
=end #(end)

module Commentable
  def self.included(base)
    base.has_many :comments, :as => :commentable, :dependent => :destroy, :order => :created_at
  end
end