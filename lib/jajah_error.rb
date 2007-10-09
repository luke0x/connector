=begin #(fold)
++
Copyright 2004-2007 Joyent Inc.

Redistribution and/or modification of this code is 
governed by the GPLv2.

Report issues and contribute at http://dev.joyent.com/

$Id$
--
=end #(end)

class JajahError < RuntimeError
  attr_reader :code
  
  def initialize(message, code)
    super(message)
    @code = code
  end
end