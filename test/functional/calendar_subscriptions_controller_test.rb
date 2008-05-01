require File.dirname(__FILE__) + '/../test_helper'
require 'calendar_subscriptions_controller'

# Re-raise errors caught by the controller.
class CalendarSubscriptionsController; def rescue_action(e) raise e end; end

class CalendarSubscriptionsControllerTest < Test::Unit::TestCase
  fixtures all_fixtures

  def setup
    CalendarSubscription::http_system = TestHttpSystem
    @controller = CalendarSubscriptionsController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
    login_person(:ian)
  end

  # REST actions
  def test_should_get_index
    get :index
    assert assigns(:calendar_subscriptions)
    assert_response :redirect
    assert_redirected_to calendar_home_url
  end

  def test_should_get_new
    get :new
    assert_response :redirect
    assert_redirected_to calendar_home_url
  end
  
  def test_should_create_calendar_subscription
    old_count = users(:ian).calendar_subscriptions.count
    post :create, :calendar_subscription => { :name => 'UK Holidays', :url => 'http://www.example.com/plain/UK32Holidays.ics', :update_frequency => 'weekly'}
    assert_equal old_count+1, users(:ian).calendar_subscriptions.count
    assert_redirected_to calendar_subscription_path(assigns(:calendar_subscription))
  end

  def test_should_show_calendar_subscription
    get :show, :id => 1
    assert_response :redirect
    assert_redirected_to calendar_subscriptions_month_route_url(:calendar_subscription_id =>1)
  end

  def test_should_get_edit
    get :edit, :id => 1
    assert_response :redirect
    assert_redirected_to calendar_subscriptions_month_route_url(assigns(:calendar_subscription))
  end
  
  def test_should_update_calendar_subscription
    put :update, :id => 1, :calendar_subscription => {:update_frequency => 'monthly' }
    assert_redirected_to calendar_subscription_path(assigns(:calendar_subscription))
  end
  
  def test_should_destroy_calendar_subscription
    old_count = users(:ian).calendar_subscriptions.count
    delete :destroy, :id => 1
    assert_equal old_count-1, users(:ian).calendar_subscriptions.count
    
    assert_redirected_to calendar_home_url
  end
  
  # Non REST:
  def test_should_get_month_view
    get :month, { :calendar_subscription_id => calendar_subscriptions(:us_holidays).id }
    assert_response :success
    assert assigns(:month_view)
    assert assigns(:calendar_subscription)
    assert assigns(:events)
  end
  
  def test_should_get_list_view
    get :list, { :calendar_subscription_id => calendar_subscriptions(:us_holidays).id }
    assert_response :success
    assert assigns(:day_views)
    assert assigns(:calendar_subscription)
    assert assigns(:events)
  end
  
  def test_should_get_event_show
    get :show_event , { :id => calendar_subscriptions(:us_holidays).id, :event_id => events(:subscription_us_holidays_easter_2007).id }
    assert_response :success
    assert assigns(:calendar_subscription)
    assert assigns(:event)
  end
  
  def test_should_refresh_subscription
    get :refresh, {:calendar_subscription_id => calendar_subscriptions(:us_holidays).id }
    assert assigns(:calendar_subscription)
    assert_response :redirect
    assert_redirected_to calendar_subscription_url(calendar_subscriptions(:us_holidays))
  end
  
  # xhr
  
  def test_should_create_calendar_through_xhr
    xhr :post, :create, :calendar_subscription => { :name => 'UK Holidays', :url => 'http://www.example.com/plain/UK32Holidays.ics', :update_frequency => 'weekly'}
    assert_response :success
    assert @response.body =~ /window\.location\.href/
  end
  
  def test_create_should_alert_problems_through_xhr
    xhr :post, :create, :calendar_subscription => { :name => 'UK Holidays', :url => 'http://www.example.com/plain/32UKHolidays.ics', :update_frequency => 'weekly'}
    assert_response :success
    assert @response.body =~ /alert/
  end
  
  def test_should_refresh_subscription_through_xhr
    xhr :get, :refresh, {:calendar_subscription_id => calendar_subscriptions(:us_holidays).id }
    assert assigns(:calendar_subscription)
    assert_response :success
    assert @response.body =~ /window\.location\.href/
  end
  
  def test_refresh_should_alert_problems_through_xhr
    # I know, this model stuff should be into another place
    # but I need to have some wrong data to raise an Exception
    us_holidays = CalendarSubscription.find(calendar_subscriptions(:us_holidays).id)
    us_holidays.username = 'wrong'
    us_holidays.save!
    
    xhr :get, :refresh, {:calendar_subscription_id => calendar_subscriptions(:us_holidays).id }
    assert_response :success
    assert @response.body =~ /alert/
  end
  
end
