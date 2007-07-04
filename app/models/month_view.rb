=begin #(fold)
Copyright 2004-2007 Joyent Inc.

Redistribution and/or modification of this code is governed
by either the GPLv2 or Joyent Commercial Software licenses.

Report issues and contribute at http://dev.joyent.com/

$Id$
=end #(end)

class MonthView < BaseView
  attr_reader   :date, :start_of_week

  def initialize(date, start_of_week=0)
    super()
    @date          = date - (date.mday() -1)
    @start_of_week = start_of_week
    @weeks         = Array.new
    @weeks[0]      = WeekView.new(@date, @start_of_week)
    
    # Get the rest of the weeks, as long as the first day of the next week is in the same month
    next_week = @weeks[-1].date + 7
    while @date.month == next_week.month do
      @weeks << WeekView.new(next_week)
      next_week = @weeks[-1].date + 7
    end
    
    @start_time = @weeks[0].start_time
    @end_time   = @weeks[-1].end_time
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
end