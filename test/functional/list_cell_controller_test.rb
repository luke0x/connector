=begin #(fold)
Copyright 2004-2007 Joyent Inc.

Redistribution and/or modification of this code is governed
by either the GPLv2 or Joyent Commercial Software licenses.

Report issues and contribute at http://dev.joyent.com/

$Id$
=end #(end)

require File.dirname(__FILE__) + '/../test_helper'
require 'list_cells_controller'

# Re-raise errors caught by the controller.
class ListCellsController; def rescue_action(e) raise e end; end

class ListCellsControllerTest < Test::Unit::TestCase
  fixtures all_fixtures
  # def setup
  #   @controller = ListCellsController.new
  #   @request    = ActionController::TestRequest.new
  #   @response   = ActionController::TestResponse.new
  #   login_person(:ian)
  # end
  # 
  # def test_set_existing_column_value
  #   text_column_value = list_cells(:list1_row1_col4)    
  #   xhr :post, :update, :id => text_column_value.id, 
  #                                 :value => "some new note"
  #   assert_response :success
  #   assert_equal "some new note", @response.body
  #   text_column_value.reload
  #   assert_equal "some new note", text_column_value.value
  # end
  # 
  # def test_set_existing_column_value_for_checkbox
  #   checkbox_column_value = list_cells(:list1_row1_col1)        
  #   xhr :post, :update, :id => checkbox_column_value.id
  #   assert_response :success
  #   assert_equal "false", @response.body
  #   checkbox_column_value.reload
  #   assert_equal "false", checkbox_column_value.value
  # end
  # 
  # def test_set_new_column_value
  #   text_column = list_columns(:list1_column4)
  #   item = list_rows(:list1_root1)
  #   
  #   xhr :post, :update, :value => "fubar"
  #   assert_response :success
  #   assert_equal "fubar", @response.body
  #   assert_equal 1, ListCell.find_all_by_value("fubar").size
  # end
  # 
  # def test_set_new_column_value_for_checkbox
  #   checkbox_column = list_columns(:list1_column1)
  #   item = list_rows(:list1_root1_child1)
  #   
  #   xhr :post, :update
  #   assert_response :success
  #   assert_equal "true", @response.body
  #   assert_not_nil checkbox_column.list_cells.find_by_list_row_id(item.id)
  # end

  def test_truth
    puts "FIX LIST CELL CONTROLLER TEST"
  end
end