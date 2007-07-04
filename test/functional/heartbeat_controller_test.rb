=begin #(fold)
Copyright 2004-2007 Joyent Inc.

Redistribution and/or modification of this code is governed
by either the GPLv2 or Joyent Commercial Software licenses.

Report issues and contribute at http://dev.joyent.com/

$Id$
=end #(end)

require File.dirname(__FILE__) + '/../test_helper'
require 'heartbeat_controller'

# Re-raise errors caught by the controller.
class HeartbeatController; def rescue_action(e) raise e end; end

class HeartbeatControllerTest < Test::Unit::TestCase
  def setup
    @controller = HeartbeatController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
  end

  def test_index
    get :index # Just needs to not vomit a 500
  end
end
