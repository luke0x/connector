=begin #(fold)
Copyright 2004-2007 Joyent Inc.

Redistribution and/or modification of this code is governed
by either the GPLv2 or Joyent Commercial Software licenses.

Report issues and contribute at http://dev.joyent.com/

$Id$
=end #(end)

class BookmarkFolder < ActiveRecord::Base
  include JoyentGroup

  has_many :bookmarks, :dependent => :destroy

  def name
    'Bookmarks'
  end

  def children
    []
  end
  
  def descendent?(group)
    false
  end

  def cascade_permissions
    users = permissions.collect(&:user)
    bookmarks.each{|b| b.restrict_to!(users)}
  end
end