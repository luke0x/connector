=begin #(fold)
Copyright 2004-2007 Joyent Inc.

Redistribution and/or modification of this code is governed
by either the GPLv2 or Joyent Commercial Software licenses.

Report issues and contribute at http://dev.joyent.com/

$Id$
=end #(end)

class WeekView < BaseView
  attr_reader :date, :start_of_week
  
  def initialize(date, start_of_week=0)
    super()
    @start_of_week = start_of_week
    offset         = (date.wday - start_of_week) % 7 # Determine the first date for the week
    @date          = date - offset
    @days          = Array.new
    (0..6).each{|num| @days << DayView.new(@date+num)}
    @start_time    = @days[0].start_time
    @end_time      = @days[-1].end_time
  end

  def events
    @days.collect(&:events).flatten.sort
  end

  def others_events_length
    @days.collect(&:others_events).collect(&:values).flatten.reject{|a| a.blank?}.length
  end

  def each(&block)
    @days.each{|day| yield day}
  end
  
  alias each_day each
  
  def take_events(events)
    @days.each {|d| d.take_events events}
  end
  
  def take_others_events(user, events)
    @days.each {|d| d.take_others_events(user, events)}
  end
end