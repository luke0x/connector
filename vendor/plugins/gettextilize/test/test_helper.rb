#!/usr/bin/env ruby
#
#  Copyright (c) 2006-2007 Joyent Inc. 
#  Licensed under the same terms as Joyent Connector.

ENV["RAILS_ENV"] = "test"
require File.expand_path(File.join(File.dirname(__FILE__),"/../../../../config/environment"))
require 'test_help'

class Test::Unit::TestCase
end