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
require 'browser_controller'

# Re-raise errors caught by the controller.
class BrowserController; def rescue_action(e) raise e end; end

class BrowserControllerTest < Test::Unit::TestCase
  fixtures all_fixtures

  def setup
    @controller = BrowserController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
    login_person(:ian)
  end

  def test_list
    get :list, {:context => 'subscribe'}
    
    assert_response :success
  end
  
  def test_column
    get :column, {:subscribable_type => 'Folder', :app => 'Files', :user_id => 1, :current_column => 'group_column', :subscribable_id => 2}
    
    assert_response :success
    assert assigns(:items)
  end
  
end
