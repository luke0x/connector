=begin #(fold)
Copyright 2004-2007 Joyent Inc.

Redistribution and/or modification of this code is governed
by either the GPLv2 or Joyent Commercial Software licenses.

Report issues and contribute at http://dev.joyent.com/

$Id$
=end #(end)

module JoyentRuby
  module Numeric
    
    def clamp(min, max)
      case
      when self < min then min
      when self > max then max
      else self
      end
    end
    
  end
end

