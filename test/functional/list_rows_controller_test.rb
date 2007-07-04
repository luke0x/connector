=begin #(fold)
Copyright 2004-2007 Joyent Inc.

Redistribution and/or modification of this code is governed
by either the GPLv2 or Joyent Commercial Software licenses.

Report issues and contribute at http://dev.joyent.com/

$Id$
=end #(end)

require File.dirname(__FILE__) + '/../test_helper'
require 'list_rows_controller'

# Re-raise errors caught by the controller.
class ListRowsController; def rescue_action(e) raise e end; end

class ListRowsControllerTest < Test::Unit::TestCase
  fixtures all_fixtures
  # def setup
  #   @controller = ListRowsController.new
  #   @request    = ActionController::TestRequest.new
  #   @response   = ActionController::TestResponse.new
  #   login_person(:ian)
  # end
  # 
  # def test_reorder_list_roots
  #   post :reorder_list, :id => lists(:list1).id, :list => [4, 1]
  #   assert_response :success
  #   
  #   assert_equal 1, ListRow.find(4).position
  #   assert_equal 2, ListRow.find(1).position
  # end
  # 
  # def test_reorder_list_root_children
  #   post :reorder_list, :id => lists(:list1).id, :item_1_children => [3, 2]
  #   assert_response :success
  #   
  #   assert_equal 1, ListRow.find(3).position
  #   assert_equal 2, ListRow.find(2).position
  # end
  
  def test_truth
    puts "FIX LIST ROWS CONTROLLER TEST"
  end
end