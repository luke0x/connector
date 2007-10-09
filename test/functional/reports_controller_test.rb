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
require 'reports_controller'

# Re-raise errors caught by the controller.
class ReportsController; def rescue_action(e) raise e end; end

class ReportsControllerTest < Test::Unit::TestCase  
  fixtures all_fixtures
  
  def setup
    @controller = ReportsController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
  end

  def test_index
    login_person(:ian)
    get :index                
    assert assigns(:group_name)
    assert_response :success 
  end  
  
  def test_create
    login_person(:ian)
    get :create, {:report_description_id => 18, :reportable_id => 1}
    assert_response :success  
  end                                                               
  
  def test_delete           
    login_person(:ian)
    pre_count = Report.count
    get :destroy, {:id => reports(:current_time).id}
    assert_response :success
    assert_equal pre_count - 1, Report.count
  end      
  
  def test_invalid_delete
    login_person(:peter)   
    pre_count = Report.count
    get :destroy, {:id => 1}
    assert_response 401
    assert_equal pre_count, Report.count
  end  
  
  def test_delete_by_type                                            
    login_person(:ian)
    pre_count = Report.count                
    get :destroy, {:report_description_id => 17, :reportable_id => 1}
    assert_response :success
    assert_equal pre_count - 1, Report.count
  end 
  
  def test_reorder                     
    login_person(:ian)
    assert_equal 1, User.find_by_username('ian').reports.first.id
    assert_equal 2, User.find_by_username('ian').reports[1].id
     
    get :reorder, {:report_list => [2,1]}  
    assert_response :success
    
    assert_equal 2, User.find_by_username('ian').reports.first.id
    assert_equal 1, User.find_by_username('ian').reports[1].id
  end  
  
  def test_invalid_ordering
    login_person(:peter) 
    get :reorder, {:report_list => [2,1]}  
    assert_response 401
    
    assert_equal 1, User.find_by_username('ian').reports.first.id
    assert_equal 2, User.find_by_username('ian').reports[1].id
  end
end
