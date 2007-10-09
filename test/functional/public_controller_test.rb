=begin #(fold)
++
Copyright 2004-2007 Joyent Inc.

Redistribution and/or modification of this code is 
governed by the GPLv2.

Report issues and contribute at http://dev.joyent.com/

$Id$
--
=end #(end)

require File.dirname(__FILE__) + '/../test_helper'
require 'public_controller'

# Re-raise errors caught by the controller.
class PublicController; def rescue_action(e) raise e end; end

class PublicControllerTest < Test::Unit::TestCase
  fixtures all_fixtures
  
  def setup
    @controller   = PublicController.new
    @request      = ActionController::TestRequest.new
    @response     = ActionController::TestResponse.new
    @request.host = domains(:joyent).web_domain
  end

  def test_true
    assert true
  end
end