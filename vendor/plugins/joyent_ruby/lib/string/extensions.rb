=begin #(fold)
Copyright 2004-2007 Joyent Inc.

Redistribution and/or modification of this code is governed
by either the GPLv2 or Joyent Commercial Software licenses.

Report issues and contribute at http://dev.joyent.com/

$Id$
=end #(end)

module JoyentRuby
  module String

    def to_num
      f = self.to_f
      i = self.to_i
      f == i ? i : f
    end

  end
end