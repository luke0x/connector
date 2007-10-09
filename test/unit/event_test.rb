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

class EventTest < Test::Unit::TestCase
  fixtures all_fixtures
  include CRUDTest

  crud_data 'organization_id'           => 1,
            'user_id'                   => 1,
            'name'                      => 'Lunch',
            'location'                  => 'Cafeteria',
            'start_time'                => Time.now + 2.hours,
            'end_time'                  => Time.now + 3.hours,
            'recur_end_time'            => Time.now + 46.days,
            'notes'                     => 'Foo',
            'all_day'                   => false,
            'recurrence_description_id' => 1
            
  crud_required 'organization_id', 'user_id',  'name', 'start_time', 'end_time'
  
  def setup
    User.current = users(:ian)
  end
  
  def test_end_time
    assert_equal (User.current.now.midnight + 40.minutes), events(:taxday).end_time
  end
  
  def test_repeat_forever
    assert events(:dailyforever).repeat_forever?
  end
  
  
  def test_invitees_accepted
    assert events(:concert).invitees_accepted.is_a?(Array)
  end
  
  def test_unaccepted
    assert events(:concert).invitees_declined.is_a?(Array)
  end
  
  def test_repeats
    assert events(:dailyforever).repeats?
    assert !events(:concert).repeats? 
  end
  
  def test_occurrences_between_for_non_repeaters
    assert_equal [events(:concert)], events(:concert).occurrences_between(1.day.ago, 1.day.from_now)
    assert_equal [], events(:concert).occurrences_between(5.years.ago, 2.years.ago)
  end
  
  def test_occurrences_between_for_repeaters
    midnight = User.current.now.midnight
    # Not inclusive of the end date
    the_repeats = events(:dailyforever).occurrences_between(midnight, (midnight + 5.days))
    assert_equal 5, the_repeats.size
    assert the_repeats.all? {|e| e.id == events(:dailyforever).id}
    the_repeats = events(:dailyforever).occurrences_between(midnight, (midnight + 5.days + 1))
    assert_equal 6, the_repeats.size
    assert the_repeats.all? {|e| e.id == events(:dailyforever).id}
  end
  
  def test_bogus_dates_to_occurrences_for_repeaters
    assert_equal [], events(:dailyforever).occurrences_between(17.days.ago, 8.days.ago)
    assert_equal [], events(:dailyforaweek).occurrences_between(25.years.from_now, 26.years.from_now)
  end 
  
  def test_from_before_start_occurrences
    the_repeats = events(:dailyforever).occurrences_between((User.current.now - 2.days), (User.current.now + 5.days))
    assert_equal 6, the_repeats.size
  end
  
  def test_to_after_end_and_from_after_start_occurrences
    midnight = User.current.now.midnight
    the_repeats = events(:dailyforaweek).occurrences_between(midnight + 3.days, midnight + 5.weeks)
    assert_equal 5, the_repeats.size
  end
  
  def test_to_after_end_and_from_before_start_occurrences
    the_repeats = events(:dailyforaweek).occurrences_between(3.days.ago.midnight, 5.weeks.from_now.midnight)
    assert_equal 8, the_repeats.size
  end
  
  def test_yearly_doesnt_barf_because_i_hate_it_so_much
    year = Time.now.year
    feb_first = Time.local(year, 2, 1, 0, 0, 0)
    aug_first = Time.local(year, 8, 1, 0, 0, 0)
    assert_equal [], events(:yearly).occurrences_between(feb_first, aug_first)
    assert_equal [], events(:yearly).occurrences_between(Time.now, 1.day.from_now)
  end
  
  def test_omgomgomgomg
    assert_equal [], events(:yearly_with_end).occurrences_between(Time.local(2006,2,3,0,0,0), Time.local(2006,4,5,0,0,0) )
  end
  
  def test_next_possible_occurence_way_off
    assert_equal [], events(:dailyforaweek).occurrences_between(10.weeks.from_now, 12.weeks.from_now)
  end
  
  def test_falls_on
    assert events(:concert).falls_on?(User.current.today)
    assert !events(:concert).falls_on?(User.current.today + 6)
    assert !events(:concert).falls_on?(User.current.today - 3)
  end
  
  def test_falls_on_over_midnight
    assert events(:oneoff_over_midnight).falls_on?(User.current.today)
    assert events(:oneoff_over_midnight).falls_on?(User.current.today - 1)
    assert !events(:oneoff_over_midnight).falls_on?(User.current.today - 2)
    assert !events(:oneoff_over_midnight).falls_on?(User.current.today + 2)
  end                                  
  
  def test_falls_on_with_zero_duration
    event = events(:taxday)
    event.end_time = event.start_time
    event.save
    assert event.falls_on?(User.current.today)
  end           
  
  def test_end_time_for_all_day
    event = events(:taxday)
    assert_equal event.start_time_in_user_tz + 1.day,  event.end_time_in_user_tz
  end
  
  def test_stub_events_fall_on
    e = events(:five_minute_daily)
    f = User.current.now.midnight - 5.minutes
    t = User.current.now + 5.days
    repeats = e.occurrences_between(f, t)
    assert repeats.first.falls_on?(User.current.today)
    assert repeats.last.falls_on?(User.current.today + 5)
    0.upto(5) do |i|
      assert repeats[i].falls_on?(User.current.today + i)
      assert_equal (User.current.now.midnight + i.days + 5.minutes), repeats[i].end_time_in_user_tz
      assert_equal e.id, repeats[i].id
      assert_equal 5.minutes, repeats[i].duration
    end
  end
           
  def test_invitation_counts
    e = events(:oneoff_over_midnight)
    e.invitations(true)
    assert_equal 0, e.accepted_invitations.size
    assert_equal 0, e.declined_invitations.size
    assert_equal 0, e.pending_invitations.size
    
    u = users(:peter)
    e.invite(u)                               
    e.invitations(true)                           
    assert_equal 0, e.accepted_invitations.size
    assert_equal 0, e.declined_invitations.size
    assert_equal 1, e.pending_invitations.size

    e.invitation_for(u).decline!    
    e.invitations(true)                           
    assert_equal 0, e.accepted_invitations.size
    assert_equal 1, e.declined_invitations.size
    assert_equal 0, e.pending_invitations.size
    
    e.invitation_for(u).accept!(calendars(:peter))    
    e.invitations(true)                           
    assert_equal 1, e.accepted_invitations.size
    assert_equal 0, e.declined_invitations.size
    assert_equal 0, e.pending_invitations.size
  end             
  
#  def test_regression_from_controller
#    f = User.current.today.to_time
#    t = (User.current.today + 6).to_time
#    assert_equal 1, events(:weekly).occurrences_between(f, t).size
#  end

  # this looks odd,  what's going on
  def test_comparable
    lt_boolean = (events(:concert) < events(:dailyforever))
    assert lt_boolean.is_a?(TrueClass) || lt_boolean.is_a?(FalseClass)

    gt_boolean = (events(:concert) > events(:dailyforever))
    assert gt_boolean.is_a?(TrueClass) || gt_boolean.is_a?(FalseClass)

    # test equality this way for coverage
    assert (events(:concert) < events(:concert)).is_a?(FalseClass)
    assert (events(:concert) > events(:concert)).is_a?(FalseClass)
    assert (events(:dailyforever) < events(:dailyforever)).is_a?(FalseClass)
    assert (events(:dailyforever) > events(:dailyforever)).is_a?(FalseClass)
  end
  
  def test_invites
    e = events(:oneoff_over_midnight)
    u = users(:peter)
    e.invite(u)
    
    assert u.invitations.collect(&:event_id).index(e.id)
  end
                 
  def test_only_one_invite
    e = events(:oneoff_over_midnight) 
    c = e.invitations.size
    u = users(:peter)
    e.invite(u)
    
    assert_equal (c + 1), Event.find(e.id).invitations.size    
    
    e.invite(u)
    assert_equal (c + 1), Event.find(e.id).invitations.size        
  end   
  
  def test_uninvite
    e = events(:oneoff_over_midnight) 
    u = users(:peter)
    
    e.invite(u)  
    assert e.invitation_for(u)        
    
    e.uninvite(u)                     
    assert_nil e.invitation_for(u)    
    
    e.invite(u)  
    assert e.invitation_for(u)
    
    e.invitation_for(u).accept!(calendars(:peter))
    
    e.uninvite(u)                     
    assert e.invitation_for(u)                             
  end
  
  def test_uninvite_owner_remains
    e = events(:concert)
    assert e.invitation_for(e.owner)
    e.uninvite(e.owner)

    e.reload
    assert e.invitation_for(e.owner)
  end
  
  # When an event was deleted, the invitations were not deleted with it
  def test_regression_for_bug_2675
    event    = events(:concert)    
    event_id = event.id    
    assert Event.find_by_id(event_id)
    
    assert event.invitations.size > 0
    invite_id = event.invitations.first.id
    assert Invitation.find_by_id(invite_id)
    
    event.destroy
    
    assert_nil Event.find_by_id(event_id)
    assert_nil Invitation.find_by_id(invite_id)
  end

  def test_move_calendar
    e = events(:concert)
    c = calendars(:anotherthing)
    
    e.move_to(c)
    
    e.reload
    
    assert e.calendars.index(c)
    assert !e.calendars.index(calendars(:concerts))
  end
  
  def test_primary_calendar
    User.current = users(:ian)
    e = events(:concert)
    assert_equal e.primary_calendar.owner, users(:ian)
  end

  def test_renotify
    e = events(:concert)
    total_notifications = Notification.count
    expected_new_notifications = e.invitations.reject{|i| i.user == e.owner}.length
    assert expected_new_notifications > 0
    e.renotify!

    assert_equal (total_notifications + expected_new_notifications), Notification.count
  end

  def test_renotify_without_others
    e = events(:taxday)
    total_notifications = Notification.count
    assert_equal 0, e.invitations.reject{|i| i.user == e.owner}.length
    e.renotify!

    assert_equal total_notifications, Notification.count
  end

  # These were both error conditions before, so no errors is good :)
  # Ticket #3612
  def test_dst
    e = events(:concert)
    e.start_time_in_user_tz = DateTime.parse("2006-10-29 12:00:00 AM").to_time(:utc)
    e.end_time_in_user_tz   = e.start_time_in_user_tz + 2.hour 
    e.save
    assert true  
    
    e.start_time_in_user_tz = DateTime.parse("2006-04-02 02:30:00 am")
    e.end_time_in_user_tz   = e.start_time_in_user_tz + 1.hour 
    e.save 
    assert true
  end  
  
  def test_alarm
    e = events(:concert)
    
    assert !e.alarm?
    
    e.update_attribute(:alarm_trigger_in_minutes, 15)
    
    assert e.alarm?
    assert_equal "-PT15M", e.ics_alarm_trigger
    assert_equal "15 minute(s) before", e.alarm_trigger_in_words
    
    e.update_attribute(:alarm_trigger_in_minutes, 60)
    
    assert e.alarm?
    assert_equal "-PT1H", e.ics_alarm_trigger
    assert_equal "1 hour(s) before", e.alarm_trigger_in_words
    
    e.update_attribute(:alarm_trigger_in_minutes, 1440)
    
    assert e.alarm?
    assert_equal "-P1D", e.ics_alarm_trigger
    assert_equal "1 day(s) before", e.alarm_trigger_in_words
    
    e.update_attribute(:alarm_trigger_in_minutes, 0)
    
    assert !e.alarm?
    assert_equal "", e.ics_alarm_trigger
    assert_equal "", e.alarm_trigger_in_words
  end
  
  
  def test_advance_simple_amounts
    t = Time.now
    assert_equal (t + 2.weeks), events(:repeating_fortnight_testing).advance(t)
  end
  
  def test_complicated_advance
    t = Time.now
    et = t.advance(:months=>1)
    assert_equal et, events(:monthly).advance(t)
  end
  
  def test_list_dates_between
    start_time = Time.local(2005, 01, 01, 0, 0, 0)
    middle_time = Time.local(2005, 01, 02, 0, 0, 0)
    end_time =Time.local(2005, 01, 03, 0, 0, 0)
    
    # NOTE: We do not want to include the end time in the 'between' calculation
    assert_equal [start_time, middle_time], events(:dailyforever).range_between(start_time, end_time)
  end
  
  # because monthly is a special case,  it gets a seperate test
  def test_normalize_dates_monthly
    m = events(:monthly)
    
    one_jan_s   = Time.local(2005, 1, 1, 0, 0, 0)
    one_jan_e   = Time.local(2005, 1, 1, 1, 0, 0)
    two_jan_s   = Time.local(2005, 1, 2, 0, 0, 0)
    two_jan_e   = Time.local(2005, 1, 2, 1, 0, 0)
    one_feb_s   = Time.local(2005, 2, 1, 0, 0, 0)
    one_feb_e   = Time.local(2005, 2, 1, 1, 0, 0)
    year_ago_s  = Time.local(2004, 1, 1, 0, 0, 0)
    year_ago_e  = Time.local(2004, 1, 1, 1, 0, 0)
    
    
    
    assert_equal one_feb_s, m.normalize(one_jan_e, 1.hour, two_jan_s)
    assert_equal one_jan_s, m.normalize(one_jan_e, 1.hour, one_jan_s)
    assert_equal one_feb_s, m.normalize(one_feb_e, 1.hour, two_jan_s)
    assert_equal one_jan_s, m.normalize(one_jan_e, 1.hour, year_ago_s)
  end
  
  def test_normalize_dates_daily
    m = events(:dailyforever)
    
    one_jan_s     = Time.local(2005, 1, 1, 0, 0, 0)
    one_jan_e     = Time.local(2005, 1, 1, 1, 0, 0)
    two_jan_s     = Time.local(2005, 1, 2, 0, 0, 0)
    two_jan_e     = Time.local(2005, 1, 2, 1, 0, 0)
    three_jan_s   = Time.local(2005, 1, 3, 0, 0, 0)
    three_jan_e   = Time.local(2005, 1, 3, 1, 0, 0)
    two_jan_3pm_s = Time.local(2005, 1, 2, 15, 0, 0)
    two_jan_3pm_e = Time.local(2005, 1, 2, 16, 0, 0)
    dec_31_2pm_s  = Time.local(2004, 12, 31, 14, 0, 0)
    dec_31_2pm_e  = Time.local(2004, 12, 31, 15, 0, 0)
    
    assert_equal one_jan_s, m.normalize(one_jan_e, 1.hour, one_jan_s)
    assert_equal three_jan_s, m.normalize(one_jan_e, 1.hour, two_jan_3pm_s)
    assert_equal one_jan_s, m.normalize(one_jan_e, 1.hour, dec_31_2pm_s)
  end
  
  def test_range_between_throws
    assert_raises(RuntimeError) { events(:monthly).range_between(2.weeks.from_now, 2.weeks.ago) }
  end
  
  def test_next_occurrence_time_non_repeating_non_all_day
    User.current = users(:ian)  
    event        = users(:ian).events.create(:organization_id => 1,
                                             :name            => "Event",
                                             :start_time      => Time.now + 20.hours,
                                             :end_time        => Time.now + 22.hours)

    assert_equal event.start_time, event.next_occurrence_time
    assert_equal event.start_time, event.next_occurrence_time(Time.now - 1.day)
    assert_nil   event.next_occurrence_time(event.start_time)
    assert_nil   event.next_occurrence_time(Time.now + 1.day) 
    assert_nil   event.next_occurrence_time(nil) 
  end                                                                          
  
  def test_next_occurrence_time_non_repeating_all_day
    
  end
  
  def test_next_occurrence_time_repeating_with_end
    User.current = users(:ian)
    event        = users(:ian).events.create(:organization_id           => 1,
                                             :name                      => "Event",
                                             :start_time                => Time.now + 1.hours,
                                             :end_time                  => Time.now + 2.hours,
                                             :recurrence_description_id => 1,
                                             :recur_end_time            => Time.now + 7.days)
                                             
    assert_equal event.start_time,         event.next_occurrence_time(Time.now - 1.day)
    assert_equal event.start_time,         event.next_occurrence_time
    assert_equal event.start_time + 1.day, event.next_occurrence_time(event.start_time)
    assert_equal event.start_time + 1.day, event.next_occurrence_time(Time.now + 1.day)
    assert_equal event.start_time + 6.day, event.next_occurrence_time(Time.now + 6.day)
    assert_nil   event.next_occurrence_time(Time.now + 7.days)
  end
  
  def test_next_occurrence_time_repeating_without_end
    User.current = users(:ian)   
    event        = users(:ian).events.create(:organization_id           => 1,
                                             :name                      => "Event",
                                             :start_time                => Time.now + 1.hours,
                                             :end_time                  => Time.now + 2.hours,
                                             :recurrence_description_id => 2)                                            
    
    assert_equal event.start_time,               event.next_occurrence_time
    assert_equal event.start_time + 7.days,      event.next_occurrence_time(Time.now + 2.hours)
    assert_equal event.start_time + (10*7).days, event.next_occurrence_time(Time.now + (10*7).days)
  end 
  
  def test_next_occurrence_time_non_constant_repeating
    User.current = users(:ian)
    event        = users(:ian).events.create(:organization_id           => 1,
                                             :name                      => "Event",
                                             :start_time                => Time.now + 1.hours,
                                             :end_time                  => Time.now + 2.hours,
                                             :recurrence_description_id => 3)                                            

    assert_equal event.start_time, event.next_occurrence_time
    assert_equal event.start_time.advance(:months => 1), event.next_occurrence_time(Time.now + 30.days)
    assert_equal event.start_time.advance(:months => 2), event.next_occurrence_time(Time.now + 60.days)
    assert_equal event.start_time.advance(:months => 3), event.next_occurrence_time(Time.now + 90.days)
  end
  
  def test_next_occurrence_time_repeating_all_day
    
  end
end