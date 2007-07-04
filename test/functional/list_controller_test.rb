=begin #(fold)
Copyright 2004-2007 Joyent Inc.

Redistribution and/or modification of this code is governed
by either the GPLv2 or Joyent Commercial Software licenses.

Report issues and contribute at http://dev.joyent.com/

$Id$
=end #(end)

require File.dirname(__FILE__) + '/../test_helper'
require 'lists_controller'

# Re-raise errors caught by the controller.
class ListsController; def rescue_action(e) raise e end; end

class ListsControllerTest < Test::Unit::TestCase
  fixtures all_fixtures
#   def setup
#     @controller = ListsController.new
#     @request    = ActionController::TestRequest.new
#     @response   = ActionController::TestResponse.new
#     login_person(:ian)
#   end
# 
#   def test_index_redirects
#     get :index
#     assert_response(:redirect)
#     assert_redirected_to lists_url(:group => 'all')
#   end
# 
#   def test_all_lists
#     get :all
#     assert_response :success
#     assert assigns(:lists)
#   end
#   
#   def test_get_list_folder
#     get :list, :group_id => list_folders(:ian_silly_lists).id
#     assert_response :success
#     assert assigns(:lists)
#   end
#   
#   def test_smart_group_attributes_are_right
#     get :all
#     assert_response :success
#     assert_smart_group_attributes_assigned smart_group_descriptions(:lists)
#   end
#   
#   def test_smart_list
#     get :smart_list, :smart_group_id => smart_groups(:ian_lists_tagged_with_orange).url_id
#     assert_response :success
#     assert assigns(:lists)
#     assert assigns(:group_name)
#     assert assigns(:smart_group)
#   end
#   
#   def test_smart_show
#     get :smart_show, :smart_group_id => smart_groups(:ian_lists_tagged_with_orange).url_id, :id => lists(:list1).id
#     assert_response :success
#     assert assigns(:list)
#     assert_equal lists(:list1).name, assigns(:list).name
#     assert assigns(:group_name)
#     assert assigns(:smart_group)
#   end
#   
# #  def test_smart_edit
# #    flunk
# #  end
#   
# #  def test_smart_delete
# #    flunk
# #  end
#   
#   def test_notifications
#     get :notifications
#     assert_response :success
#     assert assigns(:paginator)
#     assert !assigns(:notifications).blank?
#   end
#   
#   def test_peek
#     xhr :post, :peek, :id => lists(:list1).id
#     assert_response :success
#     assert assigns(:list)
#   end
#   
#   def test_create
#     post :create, :list => {:name => "my brand new list", :list_folder_id => list_folders(:ian_silly_lists)}
#     assert_response :redirect
#     new_list = List.find_by_name('my brand new list')
#     assert_not_nil new_list, "No List was created"
#     assert_redirected_to list_url(new_list)
#   end
#   
#   def test_get_show    
#     get :show, :id => lists(:list1).id    
#     assert_response :success
#   end
#   
#   def test_delete
#     post :delete, :id => lists(:list1).id
#     assert_response(:redirect)
#     assert_redirected_to lists_url(:group => 'all')
#     assert_nil List.find_by_id(1)
#   end
#   
#   def test_edit_attributes
#     columns = {}
#     lists(:list1).list_columns.each do |c|
#       columns.merge!({ c.id => {:name => c.name, :kind => c.kind} })
#     end
#     
#     lc = list_columns(:list1_column1)
#     columns[lc.id][:name] = "some new name"
#     
#     xhr :post, :edit_attributes, :id => lists(:list1).id, :list_columns => columns, :list => {:name => "A Random List"}
#     assert_response :success
#     assert_equal "A Random List", List.find(lists(:list1).id).name
#     assert_equal "some new name", ListColumn.find(lc.id).name
#   end
#   
#   def test_edit_attributes_with_new_column    
#     xhr :post, :edit_attributes, :id => lists(:list1).id, :list_column => {:name => "newcol", :kind => "Text"}
#     assert_response :success
#     newcol = ListColumn.find_by_name("newcol")
#     assert_not_nil newcol
#     assert_equal "Text", newcol.kind
#   end
#   
#   def test_delete_column
#     lc = list_columns(:list1_column1)
#     xhr :post, :delete_column, :id => lc.id, :list_id => lists(:list1).id
#     assert_response :success
#     assert_nil ListColumn.find_by_id(lc.id)
#   end
#   
#   def test_reorder_columns
#     list = lists(:list1)
#     post :reorder_columns, :id => list.id, :list_columns => [2, 1, 3, 4]
#     assert_response :success
#     
#     assert_equal 2, ListColumn.find(1).position
#     assert_equal 1, ListColumn.find(2).position
#   end
#   
#   def test_add_list_row
#     list = lists(:list1)
#     post :add_list_row, :id => list.id, :parent_id => nil
#     assert_response :success
#     list.reload
#     assert_equal 3, list.list_rows.roots.size 
#   end
#   
#   def test_add_row_to_root1
#     row = list_rows(:list1_root1)
#     post :add_list_row, :id => lists(:list1).id, :parent_id => row.id
#     assert_response :success
#     row.reload
#     assert_equal 3, row.children.size
#   end
#   
#   def test_delete_item_from_root1
#     post :delete_listrow, :id => lists(:list1).id, :list_row_id => list_rows(:list1_root1).id
#     assert_response :success
#     assert_nil ListRow.find_by_id(list_rows(:list1_root1).id)
#   end
#   
#   def test_export_to_opml
#     list = lists(:list1)
#     get :export, :id => list.id
#     assert_response :success
#     assert_equal list.to_opml, @response.body 
#   end
  
  def test_truth
    puts "FIX LIST CONTROLLER TEST"
  end
end