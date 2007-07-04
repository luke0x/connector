=begin #(fold)
Copyright 2004-2007 Joyent Inc.

Redistribution and/or modification of this code is governed
by either the GPLv2 or Joyent Commercial Software licenses.

Report issues and contribute at http://dev.joyent.com/

$Id$
=end #(end)

class Quota < ActiveRecord::Base
  belongs_to :organization
  
  def gigabytes
   	self.megabytes / 1024.0  
  end

  def gigabytes=(value)
    self.megabytes = value * 1024
  end
end