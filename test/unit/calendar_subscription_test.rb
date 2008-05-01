require File.dirname(__FILE__) + '/../test_helper'

class CalendarSubscriptionTest < Test::Unit::TestCase
  fixtures all_fixtures
  include CRUDTest
  
  def setup
    CalendarSubscription::http_system = TestHttpSystem
  end
  
  crud_data 'user_id'         => 1,
            'name'            => 'UK Holidays',
            'created_at'      => (Time.now - 7.days),
            'updated_at'      => (Time.now - 5.days),
            'organization_id' => 1,
            'url' => 'http://www.example.com/plain/UK32Holidays.ics',
            'update_frequency' => 'weekly'

  crud_required 'user_id', 'name', 'organization_id', 'url', 'update_frequency'

  def test_crud
    User.current = users(:ian)
    run_crud_tests
  end
  
  def test_should_not_be_valid_without_a_valid_update_frequency
    calendar_subscription = users(:ian).calendar_subscriptions.find(:first)
    calendar_subscription.update_frequency = 'nightly'
    assert !calendar_subscription.valid?
    assert calendar_subscription.errors.invalid?(:update_frequency)
  end
  
  def test_events_between
    User.current = users(:ian)
    # We should have a christmas event on the US Holidays calendar which repeats yearly
    assert CalendarSubscription.find(calendar_subscriptions(:us_holidays).id).events_between(Time.utc(2006,12,1), Time.utc(2007,1,31)).size > 0
    assert CalendarSubscription.find(calendar_subscriptions(:us_holidays).id).events_between(Time.utc(2007,12,1), Time.utc(2008,1,31)).size > 0
    # TODO: access restrictions test
  end
  
  def test_event_find
    User.current = users(:ian)
    assert calendar_subscriptions(:us_holidays).event_find(events(:subscription_us_holidays_easter_2007).id)
  end
  
  def test_add_event
    e = Event.new(:name       => "Independence Day",
                  :start_time => '2002-07-04 00:00:00',
                  :end_time   => '2002-07-05 00:00:00',
                  :all_day => true,
                  :recurrence_description_id => 4,
                  :recurrence_name => 'Yearly',
                  :user_id => 1,
                  :organization_id => 1)
    c = calendar_subscriptions(:us_holidays)
    
    assert c.add_event(e)
    c.reload
    assert c.events.index(e)    
  end
  
  def test_add_and_save_events             
    total_count = Event.count
    cal_count   = calendar_subscriptions(:us_holidays).events.size
    owner_count = calendar_subscriptions(:us_holidays).owner.events.size
    org_count   = calendar_subscriptions(:us_holidays).organization.events.size
    
    events = [Event.new(:name       => "Independence Day",
                        :start_time => '2002-07-04 00:00:00',
                        :end_time   => '2002-07-05 00:00:00',
                        :all_day => true,
                        :recurrence_description_id => 4,
                        :recurrence_name => 'Yearly'),
              Event.new(:name       => "New Year's Day",
                        :start_time => '2006-01-01 00:00:00',
                        :end_time   => '2006-01-02 00:00:00',
                        :all_day => true,
                        :recurrence_description_id => 4,
                        :recurrence_name => 'Yearly')]                       
    
    calendar_subscriptions(:us_holidays).add_and_save_events(events)
    
    assert_equal total_count + 2, Event.count
    assert_equal cal_count + 2,   calendar_subscriptions(:us_holidays).reload.events.size
    assert_equal owner_count + 2, calendar_subscriptions(:us_holidays).owner.events.size
    assert_equal org_count + 2,   calendar_subscriptions(:us_holidays).organization.events.size 
  end
  
  def test_delete_calendar_subscription
    c = calendar_subscriptions(:us_holidays)
    cal_count = c.events.size
    all_count = Event.count
    
    c.destroy            
    
    assert_equal Event.count, (all_count - cal_count)
  end
  
  def test_rename
    assert "US Holidays", calendar_subscriptions(:us_holidays).name
    calendar_subscriptions(:us_holidays).rename!("USA Holidays")
    assert "USA Holidays", calendar_subscriptions(:us_holidays).name
  end
  
  # Remote events related:
  def test_should_recreate_all_events_when_refresh
    c = calendar_subscriptions(:us_holidays)
    evts = c.events.collect(&:id)
    cal_count = c.events.size
    assert cal_count != 0
    assert c.refresh!
    c.reload
    assert cal_count != c.events.size
    c.events.collect(&:id).each {
      |e| assert !evts.include?(e)
    }
  end
  
  def test_should_raise_unknown_host_when_wrong_server
    c = calendar_subscriptions(:spanish_holidays)
    c.url = 'http://unknown.example.com/plain/Spain32Holidays.ics'
    assert_raise(RuntimeError, 'Cannot connect to the provided host') {
      c.refresh!
    }
  end
  
  def test_should_raise_404_when_wrong_path
    c = calendar_subscriptions(:spanish_holidays)
    c.url = 'http://www.example.com/plain/Wrong32Holidays.ics'
    assert_raise(RuntimeError, 'Cannot find the required ICS Calendar. The server returns 404 - Not found') {
      c.refresh!
    }
  end
  
  def test_should_raise_authorization_required_when_wrong_credentials
    c = calendar_subscriptions(:us_holidays)
    assert_nothing_raised(RuntimeError) {
      c.refresh!
    }
    # Wrong username
    c.username = 'foo'
    assert_raise(RuntimeError, 'Either the provided Username or Password are not valid') {
      c.refresh!
    }
    # Wrong password
    c.username = 'ian'
    c.password = 'wrong'
    assert_raise(RuntimeError, 'Either the provided Username or Password are not valid') {
      c.refresh!
    }
  end
  
  def test_should_raise_uri_error_when_not_correct
    c = calendar_subscriptions(:spanish_holidays)
    c.url = 'not/valid/url'
    assert_raise(RuntimeError, 'The provided URL is not valid') {
      c.refresh!
    }
  end
  
  def test_should_raise_invalid_protocol_when_not_http
    c = calendar_subscriptions(:spanish_holidays)
    c.url = 'ftp://www.example.com/plain/Spain32Holidays.ics'
    assert_raise(RuntimeError, 'Only http and https protocols supported') {
      c.refresh!
    }
  end
      
end
