=begin #(fold)
Copyright 2004-2007 Joyent Inc.

Redistribution and/or modification of this code is governed
by either the GPLv2 or Joyent Commercial Software licenses.

Report issues and contribute at http://dev.joyent.com/

$Id$
=end #(end)

require File.dirname(__FILE__) + '/../test_helper'

class IcalImportTest < Test::Unit::TestCase
  fixtures all_fixtures
  
  def setup
    User.current = users(:ian)  
  end
  
  def test_ical_one_all_day_one_regular
    events = events_from("Yeah Man")
    all_day = events.find {|e| e.name == "All Day"}
    assert all_day.all_day?
    assert_nil all_day.recurrence_description
    assert_equal "LOCCY", all_day.location
    assert_equal "", all_day.notes
    assert_equal Time.utc(2006,5,10), all_day.start_time
    
    e = events.find {|e| e.name == "Work too much"}
    assert !e.all_day
    assert_nil e.recurrence_description
    assert_equal "LocationyLocation", e.location
    assert_equal "Notesy Notes", e.notes
    # assert_equal Time.utc ... chris?
    assert_equal 1.hour, e.duration
    
    # no more stuff hiding in the file
    assert_equal 2, events.size
  end
  
  def test_ical_one_weekly_one_daily
    events = events_from("ICAL-Repeating")
    assert_equal 2, events.size
    
    weekly = events.find {|e| e.name == "Every Week"}
    
    assert_equal recurrence_descriptions(:weekly).name, weekly.recurrence_description.name
    assert weekly.recur_end_time < Time.utc(2006,6,4)
    
    daily = events.find {|e| e.name == "All Day"}
    assert_equal recurrence_descriptions(:daily).name, daily.recurrence_description.name
    assert daily.recur_end_time < Time.utc(2006, 5,16)
  end
  
  def test_ical_one_indefinite_daily
    events = events_from("ICAL-Indefinite")
    assert_equal 1, events.size
    e = events.first
    
    assert_equal recurrence_descriptions(:daily).name, e.recurrence_description.name
    assert e.repeat_forever?
  end
  
  def test_ical_other_repeats
    events = events_from("ICAL-Other Repeats")
    assert_equal 3, events.size
    
    monthly = events.find {|e| e.name=="Monthly"}
    assert_equal recurrence_descriptions(:monthly).name, monthly.recurrence_description.name
    
    yearly = events.find {|e| e.name=="Yearly"}
    assert_equal recurrence_descriptions(:yearly).name, yearly.recurrence_description.name
    
    fortnightly = events.find {|e| e.name=="Fortnightly"}
    assert_equal recurrence_descriptions(:fortnightly).name, fortnightly.recurrence_description.name
    
  end
  
  def test_ical_crazyass_repeat
    events = events_from("ICAL-Whacked")
    assert_equal 1, events.size
    
    assert_nil events.first.recurrence_description
  end
  
  def test_ical_finite_repeats_by_number
    events = IcalendarConverter.create_events_from_icalendar(ical_fixture("ICAL-weekly 4 times"))
    assert_equal 1, events.size
    
    e = events.first
    assert_equal recurrence_descriptions(:weekly).name, e.recurrence_description.name
    assert e.recur_end_time < (Time.utc(2006,5,10) +( 4.weeks + 1.day ))
  end
  
  def test_ical_numeric_repeats_by_number_for_other_recurrences
    events = events_from("ICAL-Remaining Numeric Repeats")
    assert_equal 3, events.size
    
    e = events.find {|e| e.name == "Fortnightly"}
    assert_equal recurrence_descriptions(:fortnightly).name, e.recurrence_description.name
    assert e.recur_end_time < (Time.utc(2006,5,9) + 7.weeks)
    
    e = events.find {|e| e.name == "Monthly"}
    assert_equal recurrence_descriptions(:monthly).name, e.recurrence_description.name
    assert e.recur_end_time < (Time.utc(2006,5,11) + 5.months)
    
    e = events.find {|e| e.name == "Yearly"}
    assert_equal recurrence_descriptions(:yearly).name, e.recurrence_description.name
    assert e.recur_end_time < (Time.utc(2021,5,13) )
  end
  
  def test_ical_all_day_events
    events = events_from("ICAL-all_day_events")
    assert_equal 9, events.size
    
    event = events.find{|e| e.name == 'Daily 3 times'}
    assert       event.all_day?
    assert_equal "20060501".to_time, event.start_time_in_user_tz
    assert_equal recurrence_descriptions(:daily).name, event.recurrence_description.name
    assert_equal ("20060503".to_time + 1), event.recur_end_time_in_user_tz
    
    event = events.find{|e| e.name == 'Yearly forever'}
    assert       event.all_day?
    assert_equal "20060501".to_time, event.start_time_in_user_tz
    assert_equal recurrence_descriptions(:yearly).name, event.recurrence_description.name
    assert_nil   event.recur_end_time_in_user_tz  
    
    event = events.find{|e| e.name == 'Weekly 2 days 4 times'}
    assert       !event.all_day?
    assert_equal "20060501".to_time, event.start_time_in_user_tz
    assert_equal "20060503".to_time, event.end_time_in_user_tz
    assert_equal recurrence_descriptions(:weekly).name, event.recurrence_description.name
    assert_equal ("20060522".to_time + 1), event.recur_end_time_in_user_tz    
    
    #should be allowed after addition of BYDAY support
    event = events.find{|e| e.name == 'Complex Repeat'}
    assert       event.all_day?
    assert_equal "20060501".to_time, event.start_time_in_user_tz
    assert       event.repeats?
    
    event = events.find{|e| e.name == 'One day'}
    assert       event.all_day?
    assert_equal 'Here', event.location
    assert_equal 'These are the notes.', event.notes
    assert_equal "20060501".to_time, event.start_time_in_user_tz
    assert       !event.repeats?
    
    event = events.find{|e| e.name == 'Two days'}
    assert       !event.all_day?
    assert_equal "20060501".to_time, event.start_time_in_user_tz
    assert_equal "20060503".to_time, event.end_time_in_user_tz
    assert       !event.repeats?
    
    event = events.find{|e| e.name == 'Monthly 2 times'}
    assert       event.all_day?
    assert_equal "20060501".to_time, event.start_time_in_user_tz
    assert       event.repeats?
    assert_equal recurrence_descriptions(:monthly).name, event.recurrence_description.name
    assert_equal ("20060601".to_time + 1), event.recur_end_time_in_user_tz
    
    event = events.find{|e| e.name == 'Daily until 5/7'}
    assert       event.all_day?
    assert_equal "20060501".to_time, event.start_time_in_user_tz
    assert       event.repeats?
    assert_equal recurrence_descriptions(:daily).name, event.recurrence_description.name
    assert_equal ("20060507".to_time + 1), event.recur_end_time_in_user_tz
     
    event = events.find{|e| e.name == 'Fortnightly'}
    assert       event.all_day?
    assert_equal "20060501".to_time, event.start_time_in_user_tz
    assert       event.repeats?
    assert_equal recurrence_descriptions(:fortnightly).name, event.recurrence_description.name
    assert_equal ("20060601".to_time + 1), event.recur_end_time_in_user_tz
  end
  
  def test_ical_pdt_events
    events = events_from("ICAL-pdt_times")
    assert_equal 6, events.size
    
    event = events.find{|e| e.name == '5/1 @ noon PDT daily until 5/5'}
    assert       !event.all_day?
    assert_equal "20060501T150000".to_time, event.start_time_in_user_tz
    assert_equal "20060501T160000".to_time, event.end_time_in_user_tz
    assert_equal 3600, event.duration
    assert       event.repeats?
    assert_equal recurrence_descriptions(:daily).name, event.recurrence_description.name
    # Don't like this result, so this can gladly change if we fix the UNTIL setting
    assert_equal ("20060506T025959".to_time), event.recur_end_time_in_user_tz
    
    event = events.find{|e| e.name == '5/1 @11p-12a PDT'}
    assert       !event.all_day?
    assert_equal "20060502T020000".to_time, event.start_time_in_user_tz
    assert_equal "20060502T030000".to_time, event.end_time_in_user_tz
    assert_equal 3600, event.duration
    assert       !event.repeats?

    event = events.find{|e| e.name == '5/2 @12a-1a PDT'}
    assert       !event.all_day?
    assert_equal "20060502T030000".to_time, event.start_time_in_user_tz
    assert_equal "20060502T040000".to_time, event.end_time_in_user_tz
    assert_equal 3600, event.duration
    assert       !event.repeats?
    
    event = events.find{|e| e.name == '5/1 @ 3-4p PDT'}
    assert       !event.all_day?
    assert_equal "20060501T180000".to_time, event.start_time_in_user_tz
    assert_equal "20060501T190000".to_time, event.end_time_in_user_tz
    assert_equal 3600, event.duration
    assert       !event.repeats?
    
    event = events.find{|e| e.name == '5/2 @11p-12a PDT'}
    assert       !event.all_day?
    assert_equal "20060503T020000".to_time, event.start_time_in_user_tz
    assert_equal "20060503T030000".to_time, event.end_time_in_user_tz
    assert_equal 3600, event.duration
    assert       !event.repeats?

    event = events.find{|e| e.name == '5/1 @12a-1a PDT'}
    assert       !event.all_day?
    assert_equal "20060501T030000".to_time, event.start_time_in_user_tz
    assert_equal "20060501T040000".to_time, event.end_time_in_user_tz
    assert_equal 3600, event.duration
    assert       !event.repeats?
  end
  
  def test_sunbird_pdt_events
    # I am currently not testing the SUNBIRD file because it is pretty inaccurate
    # Sunbird doesn't offer any timezone support in the output file, so the file
    # is as though it was in your local time zone.  So, all of the time tests would
    # really be irrelevant here.
  end
  
  def events_from(name)
    IcalendarConverter.create_events_from_icalendar(ical_fixture(name))
  end
end