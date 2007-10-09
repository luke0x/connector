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
require 'admin_controller'

# Re-raise errors caught by the controller.
class AdminController; def rescue_action(e) raise e end; end

class AdminControllerTest < Test::Unit::TestCase
  fixtures all_fixtures
  
  def setup
    @controller   = AdminController.new
    @request      = ActionController::TestRequest.new
    @response     = ActionController::TestResponse.new
  end

  def test_heartbeat
    ['1.2.3.4', 'joyent.net', 'admin.joyent.net', 'whatever.joyent.net'].each do |host|
      @request.host = host
      get :heartbeat
      assert_response :success
      assert @response.body == 'alive'
    end
  end
end