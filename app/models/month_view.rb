=begin #(fold)
++
Copyright 2004-2007 Joyent Inc.

Redistribution and/or modification of this code is 
governed by the GPLv2.

Report issues and contribute at http://dev.joyent.com/

$Id$
--
=end #(end)

class MonthView < BaseView
  EXTRA_MONTH_VIEW_WEEKS = 3
  attr_reader :start_of_week

  def initialize(date, start_of_week, current_user)
    date           -= (date.mday() -1)
    @start_of_week  = start_of_week
    @weeks          = Array.new
    @weeks[0]       = WeekView.new(date, @start_of_week, current_user)

    # Get the rest of the weeks, as long as the first day of the next week is in the same month
    next_week = @weeks[-1].date + 7
    while date.month == next_week.month do
      @weeks << WeekView.new(next_week, 0, current_user)
      next_week = @weeks[-1].date + 7
    end

    # See if today's date is in the actual month we're seeing
    today = Date.today
    next_month =  date >> 1
    if ((today <=> date) == 1) and ((today <=> next_month) == -1)
      add_additional_weeks(next_week, current_user)
    end   

    super(date, @weeks[0].start_time, @weeks[-1].end_time, current_user)
  end

  def events
    @weeks.collect(&:events).flatten.sort
  end

  def others_events_length
    @weeks.inject(0){|sum,week| week.others_events_length}
  end
  
  def week_count
    @weeks.length
  end

  def name
    Date::MONTHNAMES[@date.month]
  end

  def year
    @date.year
  end

  def each(&block)
    @weeks.each{|week| yield week}
  end
  alias each_week each

  def add_events(new_events)
    @weeks.each {|w| w.take_events(new_events) }
  end
  
  def add_others_events(user, events)
    @weeks.each {|w| w.take_others_events(user, events)}
  end

  private

  def get_week_row
    today = Date.today
    week_row = -1

    # Loop through the weeks array to find in wich position is the actual date located
    for i in 1..(@weeks.size-1)
      if ((today <=> @weeks[i].date) == -1) and ((today <=> @weeks[i-1].date) == 1)
        week_row = i
      # This is the case where the actual date is start_of_week
      elsif ((today <=> @weeks[i].date) == 0)
        week_row = i
      # If date is in the last week of the month
      elsif (i == (@weeks.size-1)) and ((today <=> @weeks[i].date) == 1) 
        week_row = @weeks.size
      end
    end
    return week_row
  end
  
  def add_additional_weeks(next_week, current_user)
    week_row = get_week_row
    additional_weeks = week_row + EXTRA_MONTH_VIEW_WEEKS - @weeks.size
    if additional_weeks > 0
      for i in 1..additional_weeks
        @weeks << WeekView.new(next_week, 0, current_user)
        next_week = @weeks[-1].date + 7
      end
    end
  end
end