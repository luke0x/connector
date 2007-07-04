=begin #(fold)
Copyright 2004-2007 Joyent Inc.

Redistribution and/or modification of this code is governed
by either the GPLv2 or Joyent Commercial Software licenses.

Report issues and contribute at http://dev.joyent.com/

$Id$
=end #(end)

module JoyentRuby
  module Object
    def subclass_responsibility
      raise 'This method should have been implemented in a subclass'
    end

    def should_not_implement
      raise 'This subclass should not implement this method'
    end

  end
end