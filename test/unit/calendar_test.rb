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
    all_count = Event.count
    
    c.destroy            
    
    assert_equal Event.count, (all_count - cal_count)
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
  
  def test_rename
    assert "Concerts", calendars(:concerts).name
    
    calendars(:concerts).rename!("Fun stuff")
    
    assert "Fun Stuff", calendars(:concerts).name
  end                
  
  def test_reparent_to_self
    assert_nil calendars(:anotherthing).reparent!(calendars(:anotherthing))
  end                      
  
  def test_reparent_to_descendent
    assert_nil calendars(:anotherthing).reparent!(calendars(:anotherthingchild))
  end
  
  def test_reparent
    assert_equal 0, calendars(:concerts).children.size
    assert       calendars(:anotherthing).reparent!(calendars(:concerts))
    assert_equal 1, calendars(:concerts).children.reload.size
  end                                                        
  
  def test_descendent                                               
    assert !calendars(:concerts).descendent?(nil)
    assert !calendars(:concerts).descendent?(calendars(:anotherthing))
    assert !calendars(:anotherthingchild).descendent?(calendars(:anotherthing))
    assert  calendars(:anotherthing).descendent?(calendars(:anotherthingchild))
    
    calendars(:anotherthing).reparent!(calendars(:concerts))
    assert calendars(:concerts).reload.descendent?(calendars(:anotherthingchild))
  end
  
  def test_add_and_save_events             
    total_count = Event.count
    cal_count   = calendars(:concerts).events.size
    owner_count = calendars(:concerts).owner.events.size
    org_count   = calendars(:concerts).organization.events.size
    
    events = [Event.new(:name       => "birthday party",
                        :location   => "house",
                        :start_time => Time.now,
                        :end_time   => Time.now + 60),
              Event.new(:name       => "fun time",
                        :location   => "house",
                        :start_time => Time.now,
                        :end_time   => Time.now + 60)]                       
    
    calendars(:concerts).add_and_save_events(events)
    
    assert_equal total_count + 2, Event.count
    assert_equal cal_count + 2,   calendars(:concerts).reload.events.size
    assert_equal owner_count + 2, calendars(:concerts).owner.events.size
    assert_equal org_count + 2,   calendars(:concerts).organization.events.size 
  end
  
  def test_remove_events_on_destoy
    # add peter's event to concerts calendar
    invite_count = users(:ian).invitations.count
    cal_count    = calendars(:concerts).events.count
    
    invite = events(:peter_concert).invite(users(:ian))
    invite.accept!(calendars(:concerts))
             
    assert       invite.accepted?
    assert_equal calendars(:concerts), invite.calendar
    assert_equal invite_count + 1, users(:ian).reload.invitations.count
    assert_equal cal_count + 1,    calendars(:concerts).reload.events.count
    
    calendars(:concerts).destroy
    assert       !invite.reload.accepted?
    assert_nil   invite.calendar
  end  
end