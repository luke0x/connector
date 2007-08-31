=begin #(fold)
Copyright 2004-2007 Joyent Inc.

Redistribution and/or modification of this code is governed
by either the GPLv2 or Joyent Commercial Software licenses.

Report issues and contribute at http://dev.joyent.com/

$Id$
=end #(end)

require File.dirname(__FILE__) + '/../test_helper'
require 'calendar_controller'

# Re-raise errors caught by the controller.
class CalendarController; def rescue_action(e) raise e end; end

class CalendarControllerTest < Test::Unit::TestCase
  fixtures all_fixtures

  def setup
    @controller = CalendarController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
    login_person(:ian)
  end
  
  def start_date
    Date.today.to_s
  end
  
  def end_date
    (Date.today + 6).to_s
  end
  
#  def test_get_list
#    get :list, {:group=>1, :start_date=>start_date, :end_date=>end_date}
#    assert_response :success
#  end

  def test_get_month_view
    get :month, { :calendar_id => calendars(:concerts).id }
    assert_response :success
    assert assigns(:month_view)
  end
  
  # also regression for 2686
  def test_get_index_redirects
    get :index, {}
    assert_response :redirect
    assert_redirected_to calendar_all_month_url
  end

  def post_to_create(event_overrides={})
    post :create, {:event=>{:name=>"Something", :all_day=>"true", 
                             :start_day=>"08", 
                             :repeat=>"", 
                             :notes=>"foo", 
                             :start_month=>"08", 
                             :start_year=>"2007", :location=>"loc loc"}.merge(event_overrides), 
                   :group=>"1"}
                   
    assert_response :redirect
    assert assigns(:event)
    assert assigns(:event).valid?
    
    id = assigns(:event).id
    
    Event.find(id) # to refresh
  end

#  def test_post_create_creates_correct_event_all_day
#    e = post_to_create
#    assert calendars(:concerts).events.index(e)
#    
#    assert_equal 1.minute, e.duration
#    
#
#    assert e.falls_on?(Date.new(2007,8,8))
#    assert !e.repeats?
#    assert e.all_day?
#  end
#  
  def test_create_with_duration_full
    e = post_to_create(:all_day=>"false", :duration_hours=>"01", :duration_minutes=>"33")
    
    assert_equal(1.hour+33.minutes, e.duration)
    assert !e.all_day?
  end

  def test_create_with_duration_hours
    e = post_to_create(:all_day=>"false", :duration_hours=>"01", :duration_minutes=>nil)
    
    assert_equal(1.hour, e.duration)
    assert !e.all_day?
  end  

  def test_create_with_duration_minutes
    e = post_to_create(:all_day=>"false", :duration_hours=>nil, :duration_minutes=>"34")
    
    assert_equal(34.minutes, e.duration)
    assert !e.all_day?
    assert !e.repeats?
  end  
  
  def test_create_with_recurrence
    e = post_to_create(:all_day=>"false", :repeat=>"daily", :repeat_forever=>true)

    assert e.repeat_forever?
    assert !e.all_day?
    assert_equal recurrence_descriptions(:daily), e.recurrence_description
  end
  
  def test_create_with_recurrence
    e = post_to_create(:all_day=>"false", :repeat=>"daily", :repeat_forever=>'false',
                       :recur_end_year=>"2007", :recur_end_month=>"01", 
                       :recur_end_day=>"01")

    assert !e.repeat_forever?
    assert !e.all_day?
    assert_equal recurrence_descriptions(:daily).name, e.recurrence_description.name
  end
  
  def test_get_create_with_start_date
    get :create, {:group=>2, :date=>users(:ian).today.to_s}
    assert_response :success
    User.current = users(:ian)
    assert assigns(:event)
    assert_equal 1.hour, assigns(:event).duration
    assert assigns(:event).falls_on?(users(:ian).today)
    
  end
  
  def test_get_create
    get :create, {:group=>2}
    assert_response :success

    assert assigns(:event)
    assert_equal 1.hour, assigns(:event).duration
  end

  def test_create_calendar_no_parent
    @request.env["HTTP_REFERER"] = '/calendar/all/list'
    post :create_calendar, {:group_name=>"Why are these still groups", :group=>calendars(:concerts).id}
    assert_response :redirect
    cal = Calendar.find_by_name("Why are these still groups")
    assert cal
    assert !cal.parent
  end
  
  def test_create_calendar_parent
    @request.env["HTTP_REFERER"] = '/calendar/all/list'
    i = calendars(:concerts).id
    post :create_calendar, {:group_name=>"Why are these still groups", :group=>i, :parent_id=>i}
    assert_response :redirect
    cal = Calendar.find_by_name("Why are these still groups")
    assert cal
    assert cal.parent
    assert_equal calendars(:concerts), cal.parent
  end

  def test_get_edit
    get :edit, {:id=>events(:dailyforever).id, :calendar_id=>calendars(:concerts).id}
    assert_response :success
    assert_template "edit"
    assert assigns(:event)
  end
  
  def test_post_edit
    post :edit, {:calendar_id=>calendars(:concerts).id, :id=>events(:dailyforever).id, 
                 :event=>{ :name=>"okay then", :all_day=>"true", 
                           :start_day=>"08", 
                           :repeat=>"", 
                           :notes=>"foo", 
                           :start_month=>"08", 
                           :start_year=>"2007", :location=>"loc loc"}}
    assert_response :redirect
    
    e = events(:dailyforever)
    e.reload
    assert_equal "okay then", e.name
  end
  
  def test_get_show
    get :show, {:calendar_id=>calendars(:concerts).id, :id=>events(:dailyforever).id}
    assert_response :success
    assert_equal events(:dailyforever), assigns(:event)
    assert_template "show"
    assert assigns(:event)
    assert_toolbar([:new, :edit, :move, :copy, :delete, :list, :month, :today, :import])
  end
     
  def test_get_show_others
    login_person(:peter)
    get :show, {:calendar_id=>calendars(:concerts).id, :id=>events(:dailyforever).id}

    assert_response :success
    assert_equal events(:dailyforever), assigns(:event)
    assert_template "show"
    assert assigns(:event)
    assert_toolbar([:new, :copy, :list, :month, :today, :import])
  end
  
  def test_get_day
    login_person(:ian)
    get :day, {:chart_date=>Date.today.to_s, :calendar_id=>calendars(:concerts).id}
    
    assert_response :success
  end
  
  def test_upload_ics
    login_person(:ian)
    post :import, :icalendar=>fixture_file_upload('/ical/Yeah Man.ics', 'text/plain'),
                  :existing_calendar=>calendars(:concerts).id,
                  :calendar_type=>'existing'
    assert_redirected_to calendar_month_route_url(:calendar_id => calendars(:concerts).id)
    assert_nil flash['error']
  end
  
  def test_upload_crap
    @request.env["HTTP_REFERER"] = "/foo"
    login_person(:ian)
    post :import, :icalendar=>fixture_file_upload('/files/rails-xtra-large-blue.jpg', 'image/jpg'),
                  :existing_calendar=>calendars(:concerts).id,
                  :calendar_type=>'existing'
    assert_response :redirect
    assert flash['error'] =~ /^There was a /
  end
  
  # regression test for case 23
  def test_upload_ics_with_missing_summary
    login_person(:ian)
    post :import, :icalendar=>fixture_file_upload('/ical/ICAL-missing_summary.ics', 'text/plain'),
                  :existing_calendar=>calendars(:concerts).id,
                  :calendar_type=>'existing'
                  
    assert_redirected_to calendar_month_route_url(:calendar_id => calendars(:concerts).id)
    assert_nil flash['error']
  end
  
  def test_smart_group_attributes_are_right
    login_person(:ian)
    get :list, {:calendar_id=>calendars(:concerts).id}    
    assert_response :success
    assert_smart_group_attributes_assigned smart_group_descriptions(:events)
    assert_toolbar([:new, :move, :copy, :delete, :month, :today, :import])
  end

  def test_all_notifications
    get :notifications, {:all => ''}

    assert_response :success
    assert assigns(:notifications)
    assert_toolbar([:new_notifications])
  end

  def test_notifications
    get :notifications, {}
    assert_response :success
    assert assigns(:notifications)
    assert_toolbar([:all_notifications])
  end                                 
  
  def test_notifications_ajax
    xhr :get, :notifications, {}
    assert_response :success
    assert assigns(:notifications)
  end  
    
  def test_todays_events
    get :todays_events       
    assert assigns(:day_views)
    assert_response :success
  end                   
  
  def test_todays_events_ajax
    xhr :get, :todays_events
    assert assigns(:day_views)
    assert_response :success    
  end                        
  
  def test_weeks_events
    get :weeks_events         
    assert assigns(:day_views)           
    assert_response :success    
  end                
  
  def test_weeks_events_ajax
    xhr :get, :weeks_events   
    assert assigns(:day_views)
    assert_response :success 
  end

  def test_regression_for_2633
    get :edit, {:id=>events(:dailyforever).id, :calendar_id=>calendars(:concerts).id}
    assert_response :success
    assert @response.body =~ /<input name="commit" type="submit" value="Save" \/>/
  end
  
  def test_delete_group
    login_person(:ian)
    i = calendars(:concerts).id
    post :delete_group, :id => i
    assert_redirected_to calendar_home_url
    assert_raises(ActiveRecord::RecordNotFound) {Calendar.find(i)}
  end

  # calendar all, month view wasn't showing up
  def test_regression_for_bug_2651
    get :all_month, {}
    assert_response :success
    assert assigns(:month_view)
    assert_toolbar([:new, :list, :today, :import])
  end

  # smart calendars were getting created, but the @smart_groups collection was accidentally getting reset to [] after loading them up
  def test_regression_for_bug_2671
    get :all_month, {}
    assert_response :success
    assert assigns(:smart_groups)
    assert assigns(:smart_groups).length > 0
    assert_toolbar([:new, :list, :today, :import])
  end

  # make sure delete buttons show up
  def test_regression_for_2656
    get :list, {:calendar_id=>calendars(:concerts).id}
    assert_response :success
    l = calendar_event_delete_url
    assert @response.body =~ /#{l}/
    assert_toolbar([:new, :move, :copy, :delete, :month, :today, :import])
  end
  
  def test_new_back_redirecting_events_delete
    @request.env["HTTP_REFERER"] = "/foo"
    i = events(:dailyforever).id.to_s
    post :delete, {:ids=>i}
    assert_redirected_to "/foo"
    assert_raises(ActiveRecord::RecordNotFound) {Event.find(i)}
  end

  # This was added to test ticket #2648, but was an attempt to be a little more thorough
  def test_list_actions
    get :list, {:calendar_id=>calendars(:concerts).id}
    assert_response :success
    assert assigns(:start_date)
    assert assigns(:end_date)
    assert assigns(:group_name)
    assert assigns(:events)
    assert assigns(:day_views)                                          
    assert_toolbar([:new, :move, :copy, :delete, :month, :today, :import])
    
    get :all_list, {}
    assert_response :success
    assert assigns(:start_date)
    assert assigns(:end_date)
    assert assigns(:group_name)
    assert assigns(:events)
    assert assigns(:day_views)
    assert_toolbar([:new, :move, :copy, :delete, :month, :today, :import])
        
    # I don't see any smart groups in the fixtures yet, so this can be added later
    #get :smart_list, {}
    #assert_response :success
    #assert assigns(:start_date)
    #assert assigns(:end_date)
    #assert assigns(:group_name)
    #assert assigns(:events)
    #assert assigns(:day_views)
  end  
  
  def test_list_actions_ajax
    xhr :get, :list, {:calendar_id=>calendars(:concerts).id}
    assert_response :success
    assert assigns(:start_date)
    assert assigns(:end_date)
    assert assigns(:group_name)
    assert assigns(:events)
    assert assigns(:day_views)                                          
    
    xhr :get, :all_list, {}
    assert_response :success
    assert assigns(:start_date)
    assert assigns(:end_date)
    assert assigns(:group_name)
    assert assigns(:events)
    assert assigns(:day_views)
  end    
                                   
  # Regression for #3033
  def test_create_from_others_calendar
    post :create, {:event=>{:name=>"Test diff calendar", :all_day=>"true", 
                             :start_day=>"08", 
                             :repeat=>"", 
                             :notes=>"foo", 
                             :start_month=>"08", 
                             :start_year=>"2007", :location=>"loc loc"}, 
                   :calendar_id=>calendars(:peter).id}
    assert_response :redirect
    assert assigns(:event)
    assert assigns(:event).valid?
    
    id = assigns(:event).id
    
    event = Event.find(id) # to refresh                           
    assert_equal event.calendars.first, users(:ian).calendars.first
  end
  
  # overlay users were not 'sticking'
  def test_regression_for_2647
    get :list, {:calendar_id=>calendars(:concerts).id}
    assert_response :success
    assert_nil session[:calendar][:overlay_users]
    @request.env["HTTP_REFERER"] = "http://www.joyent.com"
    
    get :add_overlay, {:user_id=>users(:peter).id}
    assert_response :redirect
    assert          session[:calendar][:overlay_users]
    assert_equal    users(:peter).id, session[:calendar][:overlay_users][0].to_i
  end
  
  def test_regression_for_2693
    get :smart_list, {:smart_group_id => smart_groups(:ian_foo_events).url_id}
    assert_response :success
    assert assigns(:events)
    assert_equal 0, assigns(:events).size
    assert_toolbar([:new, :move, :copy, :delete, :month, :today, :import])
  end  
                              
  # The issue was that the event didn't belong in the calendar, so 'show' didn't have an event
  def test_regression_for_2872
    get :show, {:calendar_id=>calendars(:anotherthing).id, :id=>events(:dailyforever).id}
    assert_response :redirect                                                     
  end           
                              
  # Calendar events were not getting added to other calendars besides the first                 
  def test_regression_for_2836
    post :create, {:event=>{:name=>"Test diff calendar", :all_day=>"true", 
                             :start_day=>"08", 
                             :repeat=>"", 
                             :notes=>"foo", 
                             :start_month=>"08", 
                             :start_year=>"2007", :location=>"loc loc"}, 
                   :calendar_id=>calendars(:concerts).id}
    assert_response :redirect
    assert assigns(:event)
    assert assigns(:event).valid?
    
    id = assigns(:event).id
    
    event = Event.find(id) # to refresh                           
    assert_equal event.calendars.first, calendars(:concerts)
  end                         
  
  def test_move     
    post :move, {:ids => events(:dailyforever).id, :new_group_id => calendars(:anotherthing).id} 
    assert_response :redirect              
  end          
  
  def test_copy   
    post :copy, {:ids => events(:dailyforever).id, :new_group_id => calendars(:anotherthing).id} 
    assert_response :redirect
  end        
  
  def test_peek
    login_person(:ian)
    xhr :get,  :show, {:calendar_id=>calendars(:concerts).id, :id=>events(:dailyforever).id}
    assert_response :success
    assert_template '_peek'
  end
  
  def test_preview   
    xhr :post, :show, {:calendar_id=>calendars(:concerts).id, :id=>events(:dailyforever).id}
                                                                              
    assert_response :success                                     
    assert assigns(:event)                             
    assert_equal events(:dailyforever), assigns(:event)
    assert_template '_peek'
  end 

  def test_rename_group
    @request.env["HTTP_REFERER"] = "http://www.joyent.com/calendar/all"

    assert_equal calendars(:concerts).name, 'Concerts'
    post :rename_group, :id => calendars(:concerts).id, :name => 'Agile'
    calendars(:concerts).reload
    assert_equal calendars(:concerts).name, 'Agile'
  end

  # make sure that one calendar is always left
  def test_delete_calendar_leaves_one
    users(:ian).calendars.find(:all, :conditions => [ "parent_id IS NULL"]).each do |c|
      post :delete_group, :id => c.id
    end
    users(:ian).reload
    assert_equal 1, users(:ian).calendars.length
    assert_equal users(:ian).calendars.first.name, users(:ian).full_name
  end

  def test_reparent_group
    @request.env["HTTP_REFERER"] = "http://www.joyent.com/calendar/all/month"
    assert_nil calendars(:anotherthing).parent
    post :reparent_group, :group_id => calendars(:anotherthing).id, :new_parent_id => calendars(:concerts).id

    calendars(:anotherthing).reload
    assert_equal calendars(:anotherthing).parent.id, calendars(:concerts).id
  end

  # don't let a group get moved illegally
  def test_reparent_group_doesnt_work
    @request.env["HTTP_REFERER"] = "http://www.joyent.com/calendar/all/month"
    assert_nil calendars(:anotherthing).parent
    assert_equal calendars(:anotherthingchild).parent.id, calendars(:anotherthing).id
    post :reparent_group, :group_id => calendars(:anotherthing).id, :new_parent_id => calendars(:anotherthingchild).id

    calendars(:anotherthing).reload
    assert_equal calendars(:anotherthingchild).parent.id, calendars(:anotherthing).id
  end
  
  # Regression test for 2887
  # Can only delete events you own
  def test_non_owner_delete
    @request.env["HTTP_REFERER"] = "http://www.joyent.com"  
    assert Event.find(events(:dailyforever).id)
    post :delete, {:ids => events(:dailyforever).id}, {:user_id=>users(:peter).id} 
    assert Event.find(events(:dailyforever).id)
  end

  # didn't have the form url correct
  def test_regression_for_3230
    get :month, { :calendar_id => calendars(:concerts).id }
    assert @response.body =~ /#{calendar_import_url}/
  end

  # should happen since the time is changing
  def test_renotification_happens
    e = events(:concert)
    notification_count = e.notifications.count
    assert e.invitations.reject{|i| i.user == e.owner}.length > 0
    post :edit, {:calendar_id=>calendars(:concerts).id,
                 :id=>e.id, 
                 :event=>{ :name             => 'whatever, dude',
                           :all_day          => e.all_day, 
                           :start_year       => e.start_time_in_user_tz.year,
                           :start_month      => e.start_time_in_user_tz.month, 
                           :start_day        => e.start_time_in_user_tz.day, 
                           :start_hour       => e.start_time_in_user_tz.strftime('%I'), 
                           :start_minute     => (e.start_time_in_user_tz.strftime('%M').to_i + 1).to_s, 
                           :start_ampm       => e.start_time_in_user_tz.strftime('%p').downcase, 
                           :duration_hours   => e.duration / 1.hour,
                           :duration_minutes => (e.duration - (e.duration / 1.hour).hours) / 1.minute,
                           :repeat           => (e.repeats? ? e.repeats?.name.downcase : '' ), 
                           :repeat_forever   => (e.repeats? && e.end_time_in_user_tz).to_s,
                           :recur_end_year   => (e.recur_end_time_in_user_tz.year  rescue nil),
                           :recur_end_month  => (e.recur_end_time_in_user_tz.month rescue nil), 
                           :recur_end_day    => (e.recur_end_time_in_user_tz.day   rescue nil), 
                           :notes            => e.notes, 
                           :location         => e.location}}

    e.reload
    assert e.notifications.count > notification_count
  end

  # shouldn't happen when only the name changes
  def test_renotification_doesnt_happen
    e = events(:concert)
    notification_count = e.notifications.count
    post :edit, {:calendar_id=>calendars(:concerts).id,
                 :id=>e.id, 
                 :event=>{ :name             => 'whatever, dude',
                           :all_day          => e.all_day, 
                           :start_year       => e.start_time_in_user_tz.year,
                           :start_month      => e.start_time_in_user_tz.month, 
                           :start_day        => e.start_time_in_user_tz.day, 
                           :start_hour       => e.start_time_in_user_tz.strftime('%I'), 
                           :start_minute     => e.start_time_in_user_tz.strftime('%M'), 
                           :start_ampm       => e.start_time_in_user_tz.strftime('%p').downcase, 
                           :duration_hours   => e.duration / 1.hour,
                           :duration_minutes => (e.duration - (e.duration / 1.hour).hours) / 1.minute,
                           :repeat           => (e.repeats? ? e.repeats?.name.downcase : '' ), 
                           :repeat_forever   => (e.repeats? && e.end_time_in_user_tz).to_s,
                           :recur_end_year   => (e.recur_end_time_in_user_tz.year  rescue nil),
                           :recur_end_month  => (e.recur_end_time_in_user_tz.month rescue nil), 
                           :recur_end_day    => (e.recur_end_time_in_user_tz.day   rescue nil), 
                           :notes            => e.notes, 
                           :location         => e.location}}

    e.reload
    assert_equal notification_count, e.notifications.count
  end
  
  #regression test for case #4013
  def test_declines_event_notificaion
    e = events(:concert)
    
    login_person(:peter)
    post :invitations_decline, {:id => e.id}
    
    e.reload
    invitation = e.invitation_for(users(:peter))
    assert_equal nil, invitation.calendar
  end

end