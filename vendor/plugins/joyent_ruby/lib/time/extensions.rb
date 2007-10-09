=begin #(fold)
++
Copyright 2004-2007 Joyent Inc.

Redistribution and/or modification of this code is 
governed by the GPLv2.

Report issues and contribute at http://dev.joyent.com/

$Id$
--
=end #(end)

module JoyentRuby
  module Time
    def midnight?
      self.hour == 0 and
      self.min == 0 and
      self.sec == 0
    end
  end
end