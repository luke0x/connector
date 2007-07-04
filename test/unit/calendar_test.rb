=begin #(fold)
Copyright 2004-2007 Joyent Inc.

Redistribution and/or modification of this code is governed
by either the GPLv2 or Joyent Commercial Software licenses.

Report issues and contribute at http://dev.joyent.com/

$Id$
=end #(end)

require File.dirname(__FILE__) + '/../test_helper'

class CalendarTest < Test::Unit::TestCase
  fixtures all_fixtures
  include CRUDTest

  crud_data 'user_id'         => 1,
            'name'            => 'Movies',
            'created_at'      => (Time.now - 7.days),
            'updated_at'      => (Time.now - 5.days),
            'organization_id' => 1

  crud_required 'user_id', 'name', 'organization_id'

  def test_crud
    User.current = users(:ian)
    Organization.current = User.current.organization
    run_crud_tests
  end

  def test_add_event
    e = events(:dailyforever)
    c = calendars(:anotherthing)
    
    invitation = c.add_event(e)
    assert invitation.accepted?
    c.reload
    assert c.events.index(e)    
  end
  
  def test_event_find
    User.current = users(:ian)
    assert calendars(:concerts).event_find(events(:concert).id)
  end                    
               
  # Regression test for #3060
  def test_events_between_with_no_access
    User.current = users(:ian)
    assert Calendar.find(calendars(:peter).id).events_between(Time.now - 7.days, Time.now + 7.days).size > 0
    
    User.current = users(:peter)
    Calendar.find(calendars(:peter).id).restrict_to!([users(:peter)])

    User.current = users(:ian)
    assert Calendar.find(calendars(:peter).id).events_between(Time.now - 7.days, Time.now + 7.days).size == 0
  end
  
  def test_event_find_event_but_not_on_calendar
    User.current = users(:ian)
    c = calendars(:concerts)

    assert_nil c.event_find(events(:another_thing_event).id)
  end
  
  def test_event_find_event_on_empty_calendar
    User.current= users(:ian)
    c = calendars(:noevents)
    assert_nil c.event_find(events(:another_thing_event).id)
  end
  
  def test_delete_calendar
    c = calendars(:concerts)
    cal_count = c.events.size
    all_count = Event.find(:all).size
    
    c.destroy            
    
    assert_equal Event.find(:all).size, (all_count - cal_count)
  end

  def test_cascade_permissions
    User.current = users(:ian)

    assert calendars(:anotherthing).permissions.empty?
    assert calendars(:anotherthing).children.first.permissions.empty?
    assert calendars(:anotherthing).events.first.permissions.empty?
    
    calendars(:anotherthing).restrict_to!([users(:ian)])
    assert_equal 1, calendars(:anotherthing).permissions.length
    assert_equal users(:ian), calendars(:anotherthing).permissions.first.user
    assert_equal 1, calendars(:anotherthing).children.first.permissions.length
    assert_equal users(:ian), calendars(:anotherthing).children.first.permissions.first.user
    assert_equal 1, calendars(:anotherthing).events.first.permissions.length
    assert_equal users(:ian), calendars(:anotherthing).events.first.permissions.first.user
  end
  
  def test_calendar_has_subscriptions
    User.current = users(:jason)

    assert_not_nil calendars(:anotherthing).subscriptions.find_by_user_id(User.current.id)
  end
  
end