=begin #(fold)
++
Copyright 2004-2007 Joyent Inc.

Redistribution and/or modification of this code is 
governed by the GPLv2.

Report issues and contribute at http://dev.joyent.com/

$Id$
--
=end #(end)

module Taggable
  def self.included(base)
    base.has_many :taggings, :as      => :taggable, :dependent => :destroy
    base.has_many :tags,     :through => :taggings
  end
end