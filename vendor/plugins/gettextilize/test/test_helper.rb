#!/usr/bin/env ruby
=begin #(fold)
++
Copyright 2004-2007 Joyent Inc.

Redistribution and/or modification of this code is 
governed by the GPLv2.

Report issues and contribute at http://dev.joyent.com/

$Id$
--
=end #(end)

ENV["RAILS_ENV"] = "test"
require File.expand_path(File.join(File.dirname(__FILE__),"/../../../../config/environment"))
require 'test_help'

class Test::Unit::TestCase
end