=begin #(fold)
Copyright 2004-2007 Joyent Inc.

Redistribution and/or modification of this code is governed
by either the GPLv2 or Joyent Commercial Software licenses.

Report issues and contribute at http://dev.joyent.com/

$Id$
=end #(end)

class Event < ActiveRecord::Base
  include Comparable
  include JoyentItem

  before_save   :set_sort_caches
  
  serialize :by_day, Array

  validates_presence_of :name
  validates_presence_of :start_time
  validates_presence_of :end_time
  
  has_many   :invitations, :dependent => :destroy
  has_many   :calendars,   :through   => :invitations
  has_many   :users,       :through   => :invitations
  
  def self.search_fields
    [
      'users.username',
      'events.location',
      'events.notes',
      'events.name',
      'events.recurrence_name'
    ]
  end
  
  Rd = RecurrenceDescription.new(:name, :rule_text, :id, :seconds_to_increment, :advance_arguments)
  
  def Event.from_icalendar(icalendar_content)
    IcalendarConverter.create_events_from_icalendar(icalendar_content)
  end
  
  def duration
    @__duration ||= all_day? ? 1.day : (end_time - start_time).to_i
  end

  def repeat_forever?
    repeats? && !recur_end_time
  end
  
  def repeats?
    recurrence_description
  end
  
  def falls_on?(date)
    Event.falls_on?(self, date)
  end

  def between?(local_start_time, local_end_time)
    Event.between?(self, local_start_time, local_end_time)
  end

  def overlaps?(startt, endt)
    Event.overlaps?(self, startt, endt)
  end
  
  def invite(user)
    return if invitation_for(user)
    Invitation.create(:user_id=>user.id, :event_id=>id)
  end  
  
  # Won't allow you to uninvite if an invitation has already been responded to
  def uninvite(user)
    return unless invite = invitation_for(user)
    return unless invite.pending?
    return if invite.user == owner and calendars.select{|c| c.owner == owner}.length == 1

    invite.destroy
  end

  # 'renotifies' all invitees, for when the event has changed
  def renotify!
    invitations.find(:all, :conditions => ["user_id <> ?", user_id]).each do |invitation|
      invitation.accepted = false
      invitation.pending = true
      invitation.save!
      invitation.user.notify_of(self, self.owner)
    end
  end
  
  def move_to(calendar)
    user = calendar.owner
    # find the calendar the user's storing this event on
    invite = invitations.find(:first, :conditions=>["user_id = ?", user.id])
    if invite && invite.calendar
      old_calendar = invite.calendar
      invite.calendar = calendar
      invite.save!
    end
  end       
  
  def copy_to(calendar)
    new_event       = Event.create(self.attributes)
    new_event.owner = calendar.owner
    new_event.save
    calendar.add_event(new_event)
    permissions.each {|perm| new_event.permissions.create(perm.attributes)} 
    
    new_event
  end
  
  def invitation_for(user)
    self.invitations.find_by_user_id(user.id)
  end  
  
  def accepted_invitations
    self.invitations(true).select{|invite| ! invite.pending? && invite.accepted?} - [self.invitation_for(self.owner)]
  end
  
  def declined_invitations
    self.invitations(true).select{|invite| ! invite.pending? && !invite.accepted?} - [self.invitation_for(self.owner)]
  end
  
  def pending_invitations
    self.invitations(true).select{|invite| invite.pending?} - [self.invitation_for(self.owner)]
  end

  def invitees_accepted
    self.accepted_invitations.collect(&:user).sort
  end

  def invitees_declined
    self.declined_invitations.collect(&:user).sort
  end
  
  def invitees_pending
    self.pending_invitations.collect(&:user).sort
  end
  
  def alarm?
    self.alarm_trigger_in_minutes && self.alarm_trigger_in_minutes > 0
  end
  
  def alarm_trigger_in_words
    return '' unless alarm?
    
    # I realize this is ghetto, but I assume this would all go when alarms get implemented correctly :)
    ics_alarm_trigger[2..-1].gsub('D', ' day(s)').gsub('T', '').gsub('H', ' hour(s)').gsub('M', ' minute(s)') + ' before'
  end
  
  def ics_alarm_trigger
    return '' unless self.alarm?
    
    trigger = '-P'
    minutes = self.alarm_trigger_in_minutes

    days = minutes / (1.day / 60)    
    if days > 0
      trigger += "#{days}D"
      minutes -= days * (1.day / 60) 
    end 
    
    unless minutes == 0
      trigger += 'T'
      
      hours = minutes / 60
      if hours > 0
        trigger += "#{hours}H"
        minutes -= hours * 60
      end
      
      if minutes > 0
        trigger += "#{minutes}M"
      end  
    end
    
    trigger    
  end

  #####
  # HACK: These methods are added to make dealing with timezones much easier
  #####
  
  # Since I am not going to hack the all_day setter, be sure to set the ALL_DAY status
  # BEFORE setting the start_time
  def start_time_in_user_tz
    @__stiutz ||= (all_day? ? start_time : to_local(start_time))
  end
  
  def start_time_in_user_tz=(value)
    self.start_time = all_day? ? value.midnight : to_utc(value)
  end
  
  def end_time_in_user_tz
    @__etiutz ||= (all_day? ? start_time_in_user_tz + 1.day : to_local(end_time))
  end           
  
  def end_time_in_user_tz=(value)
    self.end_time = all_day? ? value : to_utc(value)
  end
  
  def recur_end_time_in_user_tz
    @__retiutz ||= (all_day? ? recur_end_time : to_local(recur_end_time))
  end
  
  # May want to bring the logic of the recur_end time is start_time + 1s
  def recur_end_time_in_user_tz=(value)
    if value
      self.recur_end_time = all_day? ? value.midnight + 1 : to_utc(value)
    else
      self.recur_end_time = nil
    end
  end
  
  def <=>(right_side)
    if start_time_in_user_tz == right_side.start_time_in_user_tz
      return  0  if all_day? && right_side.all_day?
      return -1  if all_day?
      return  1  if right_side.all_day?
      return  0
    else
      return start_time_in_user_tz <=> right_side.start_time_in_user_tz
    end
  end
  
  ### Date based operations
  def occurrences_between(local_start_time, local_end_time)
    raise "Local start time is nil" if local_start_time.blank?
    raise "Local end time is nil" if local_end_time.blank?

    if !repeats?
      # is it in the range
      if self.start_time_in_user_tz < local_end_time && self.end_time_in_user_tz > local_start_time
        return [self]
      else
        return []
      end
    end 
    
    # Repeating events
    # first sanitize the start_time so it aligns with the event's cycle
    from_time = normalize(self.end_time_in_user_tz, self.duration, local_start_time)
    
    # pin the end time to this event's recurrence end, assuming it has one
    if self.recur_end_time_in_user_tz && self.recur_end_time_in_user_tz < local_end_time
      local_end_time = self.recur_end_time_in_user_tz
    end

    if from_time > local_end_time
      # The next possible recurrence is outside the provided range
      return []
    elsif self.recur_end_time_in_user_tz && self.recur_end_time_in_user_tz < from_time
      # the next possible recurrence is outside this events range
      return []
    end

    dates = range_between(from_time, local_end_time)
    dates.collect{|t| StubEvent.new(self, t)}
  end
  
  def self.falls_on?(event, local_date)
    local_start_time = local_date.to_time(:utc).midnight
    local_end_time   = local_start_time + 1.day
    between?(event, local_start_time, local_end_time)
  end
  
  def self.between?(event, local_start_time, local_end_time)
    startt = event.start_time_in_user_tz
    endt   = event.end_time_in_user_tz
    
    (startt < local_end_time && endt > local_start_time) ||
    (startt == endt && startt == local_start_time)
  end

  # TODO: needs tests
  def self.overlaps?(event, local_start_time, local_end_time)
    startt = event.start_time_in_user_tz
    endt   = event.end_time_in_user_tz

    (startt >= local_start_time and startt < local_end_time) or
    (startt <= local_start_time and endt >= local_end_time) or
    (endt > local_start_time and endt <= local_end_time)
  end
  
  #####
  # END HACK
  #####
  
  def primary_calendar
    calendars.find(:first, :conditions => ['users.id = ?', owner.id], :scope => :read)
  end
  
  def class_humanize
    'Event'
  end

  def update_from_params(event_params)
    event_params[:all_day] = (event_params[:all_day] == 'true') ? true : false

    # set the start_time
    if !event_params[:start_year].blank? and !event_params[:start_month].blank? and !event_params[:start_day].blank?
      # fix the times if needed
      event_params[:start_minute] = '00' if event_params[:start_minute].blank?
      event_params[:start_hour]   = '00' if event_params[:start_hour].blank?
      event_params[:start_hour]   = event_params[:start_hour].to_i
 
      if event_params[:start_ampm] == 'pm'
        event_params[:start_hour] += 12
      end

      if event_params[:start_hour] == 12 || event_params[:start_hour] == 24
        event_params[:start_hour] -= 12
      end

      begin
        event_params[:start_time] = Time.utc(event_params[:start_year].to_i, 
                                             event_params[:start_month].to_i, 
                                             event_params[:start_day].to_i, 
                                             event_params[:start_hour].to_i, 
                                             event_params[:start_minute].to_i, 
                                             0, 
                                             0)
      rescue ArgumentError
        return  
      end                                            
    end

    # set the duration
    if event_params[:all_day]
      event_params[:duration] = 1.minute
    else
      event_params[:duration] = event_params[:duration_hours].to_i.hours + event_params[:duration_minutes].to_i.minutes rescue nil
    end

    # set the recur rule
    event_params[:recurrence_description_id] = Event.recurrence_map[event_params[:repeat]]

    # set the end time
    if !event_params[:repeat].blank?            &&
       event_params[:repeat_forever] == 'false' &&
       !event_params[:recur_end_year].blank?    &&
       !event_params[:recur_end_month].blank?   &&
       !event_params[:recur_end_day].blank?

       begin
         event_params[:recur_end_time] = Time.utc(event_params[:recur_end_year].to_i,
                                                  event_params[:recur_end_month].to_i,
                                                  event_params[:recur_end_day].to_i,
                                                  event_params[:start_hour].to_i,
                                                  event_params[:start_minute].to_i,
                                                  1,
                                                  0)
       rescue ArgumentError
         return  
       end                            
    else
      event_params[:recur_end_time] = nil
    end

    # renotify if something key has changed
    remember_to_renotify =  self.all_day                   != event_params[:all_day] ||
                            self.start_time_in_user_tz     != event_params[:start_time] ||
                            self.end_time_in_user_tz       != (event_params[:start_time] + event_params[:duration]) ||
                            self.recurrence_description_id != event_params[:recurrence_description_id] ||
                            self.recur_end_time_in_user_tz != event_params[:recur_end_time] ||
                            self.location                  != event_params[:location]

    self.name                      = event_params[:name]
    self.all_day                   = event_params[:all_day]
    self.start_time_in_user_tz     = event_params[:start_time]
    self.end_time_in_user_tz       = event_params[:start_time] + event_params[:duration]
    self.recurrence_description_id = event_params[:recurrence_description_id]
    self.recur_end_time_in_user_tz = event_params[:recur_end_time]
    self.location                  = event_params[:location]
    self.notes                     = event_params[:notes]
    self.alarm_trigger_in_minutes  = event_params[:alarm_trigger_in_minutes]
    self.organization              = Organization.current
    self.owner                     = User.current
    self.by_day                    = event_params[:by_day]
    self.save

    if self.valid? && remember_to_renotify
      self.renotify!
    end

    self
  end     

  def recurrence_description
    case self.recurrence_description_id
    when 1 then Rd.descriptions(:daily)
    when 2 then Rd.descriptions(:weekly)
    when 3 then Rd.descriptions(:monthly)
    when 4 then Rd.descriptions(:yearly)
    when 5 then Rd.descriptions(:fortnightly)
    end
  end
  
  def self.recurrence_map
    { 'daily' => 1, 'weekly' => 2, 'monthly' => 3, 'yearly' => 4, 'fortnightly' => 5 }
  end
  
  def by_day_map
    { :su => 0, :mo => 1, :tu => 2, :we => 3, :th => 4, :fr => 5, :sa => 6 }
  end
  
  def by_day_word_map
    { 'su' => 'Sunday', 'mo' => 'Monday', 'tu' => 'Tuesday', 'we' => 'Wednesday', 'th' => 'Thursday', 'fr' => 'Friday', 'sa' => 'Saturday' }
  end
  
  # Cannot be inclusive of the end_time b/c more than likely, the queries will go from time_1 to time_2,
  # time_2 to time_3, time_3 to time_4, etc
  def range_between(start_time, end_time)
    if end_time < start_time
      raise "Invalid argument, #{end_time} <= #{start_time}, which won't work for #{self.recurrence_description_id}"
    end
    
    times = []
    new_time = start_time
    while new_time < end_time
      times << new_time
      
      new_time = advance(new_time)
    end
    times
  end
  
  def days_to_next(current)    
    if days = self.by_day.detect{|d| by_day_map[d.to_sym] > current.wday}
      by_day_map[days.to_sym] - current.wday
    else
      7 - (current.wday - by_day_map[self.by_day.detect{|d| by_day_map[d.to_sym] <= current.wday }.to_sym])
    end
  end
  
  # Need to find the first repeating event that has an END_TIME that is after the range start time
  def normalize(end_time, duration, time_to_normalize)
    until end_time > time_to_normalize
      end_time = advance(end_time)
    end

    end_time - duration
  end
  
  def advance(time)
    if self.by_day
      time.advance(:days => days_to_next(time))
    elsif self.recurrence_description.seconds_to_increment < 0
      time.advance(self.recurrence_description.advance_arguments.dup) # critical as advance calls hash.delete and you just loop
    else
      time + self.recurrence_description.seconds_to_increment
    end
  end
  
  #lame since serialize can't handle nils
  def by_day
    unless self[:by_day].nil? 
      self[:by_day]
    end
  end
  
  def by_day_in_words
    self.by_day.collect {|d| by_day_word_map[d] + ', '}
  end
  
  private

    def to_utc(time)
      if User.current && time
        begin
          User.current.person.tz.local_to_utc(time)
        rescue TZInfo::AmbiguousTime 
          User.current.person.tz.local_to_utc(time, true) 
        rescue TZInfo::PeriodNotFound
          User.current.person.tz.local_to_utc(time + 1.hour)
        end
      end
    end
  
    def to_local(time)
      if User.current && time
        User.current.person.tz.utc_to_local(time)
      end
    end

    def set_sort_caches
      self.recurrence_name = recurrence_description ? recurrence_description.name : ''
    end
end