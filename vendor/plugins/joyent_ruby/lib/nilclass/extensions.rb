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
  module NilClass
    
    def id
      raise ArgumentError, "Error calling nil.id"
    end
    
  end
end