=begin #(fold)
++
Copyright 2004-2007 Joyent Inc.

Redistribution and/or modification of this code is 
governed by the GPLv2.

Report issues and contribute at http://dev.joyent.com/

$Id$
--
=end #(end)

class Chown
  def self.chown_R(user, group, list, options={})
    return if RAILS_ENV == 'development'
    MockFS.file_utils.chown_R(user, group, list, options)
  end
end