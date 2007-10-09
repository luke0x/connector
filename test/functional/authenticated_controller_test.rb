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
require 'authenticated_controller'
require 'files_controller'

# Re-raise errors caught by the controller.
class AuthenticatedController; def rescue_action(e) raise e end; end

class AuthenticatedControllerTest < Test::Unit::TestCase
  fixtures all_fixtures

  def setup
    @controller = FilesController.new  # pick an innocuous controller
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
    login_person(:ian)
  end
  
  def test_is_authenticated
    assert @controller.is_a?(AuthenticatedController)
  end

  def test_children_groups
    assert folders(:ian_pictures).children.length > 0
    get :children_groups, {:id => folders(:ian_pictures).id}
    
    assert_response :success
    assert @response.body =~ /^\s*<ul>/
  end

  def test_children_groups_empty
    assert folders(:ian_pictures_vacation).children.length == 0
    get :children_groups, {:id => folders(:ian_pictures_vacation).id}
    
    assert_response :success
    assert_equal '', @response.body.strip
  end

  def test_children_groups_invalid
    get :children_groups, {:id => -1}
    assert_equal @response.body, 'No children groups found'
  end
end