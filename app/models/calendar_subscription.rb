=begin #(fold)
++
Copyright 2004-2007 Joyent Inc.

Redistribution and/or modification of this code is 
governed by the GPLv2.

Report issues and contribute at http://dev.joyent.com/

$Id$
--
=end #(end)

class CalendarSubscription < ActiveRecord::Base
  include JoyentGroup
  
  validates_presence_of :name, :url
  validates_inclusion_of :update_frequency, :in => ['weekly', 'monthly', 'never']
  
  has_many :events, :dependent => :destroy
  
  @@http_system = ProductionHttpSystem
  
  def self.frequencies
    [['Weekly',:weekly], ['Monthly',:monthly], ['Never', :never]]
  end
  
  # Almost the Calendar Method without :permissions, :notifications and :taggings
  def events_between(start_time, end_time)
    raise ArgumentError, "Start time is nil" if start_time.blank?
    raise ArgumentError, "End time is nil"   if end_time.blank?    

    events = self.events.find(:all, :include => [{:owner => :person}], :scope => :read)
    events.collect{|e| e.occurrences_between(start_time, end_time)}.flatten.sort
  end
  
  # Almost the Calendar Method, without :invitations
  def event_find(id)
    Event.find(:first, :conditions => [ 'events.id = ?', id ], :scope => :read)
  end
  
  # No :invitations for CalendarSubscription
  def add_event(event)
    event.calendar_subscription_id = self.id
    event.save!
  end
  
  # Same thing than on Calendar Model. This is only importing stuff, indeed.
  def add_and_save_events(events)
    Event.transaction do
      events.each do |event|   
        event.owner = owner
        event.organization = owner.organization
        event.save!
        add_event(event)  
      end
    end
  end
  
  # Same thing than on Calendar
  def rename!(name)  
    update_attribute(:name, name)
  end
  
  # Workaround, cause this is not using acts_as_tree
  def parent
    self
  end
  
  # Retrieve all the events from remote Calendar and override the existing ones
  def refresh!
    events_from_remote_icalendar
  end
  
  # Override create method to include the remote calendar events after successful save
  def create
    super
    events_from_remote_icalendar
    self
  end
  
  # Connect to the current CalendarSubscription url with the provided credentials, if any
  # trying to retrieve the ics file contents, parse them and add those to the current 
  # CalendarSubscription. Note that it will raise any exception on the process.
  # All the Exceptions comming from ProductionHttpSystem are localized in order to be able
  # to use them into UI. 
  def events_from_remote_icalendar
    begin
      response  = @@http_system::get_response_by_url(self.url, self.username, self.password, JoyentConfig.http_max_redirects)
      raw_events = response.body
      events = IcalendarConverter.create_events_from_icalendar(raw_events)
      unless self.new_record?
        self.events.clear
      end
      add_and_save_events(events)
    rescue
      # Remember to handle Exceptions from the caller!
      raise
    end
  end
  
  # This is just to be able to override it for testing
  def self.http_system=(http_system)
    @@http_system = http_system
  end
  
end
