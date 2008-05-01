#!/usr/bin/env ruby
# ++
# Copyright 2004-2007 Joyent Inc.
# 
# Redistribution and/or modification of this code is 
# governed by the GPLv2.
# 
# Report issues and contribute at http://dev.joyent.com/
# 
# $Id$
# --


require File.dirname(__FILE__) + '/../config/boot'
# It complains about a file being required without RAILS_ROOT appended
begin
  require "#{RAILS_ROOT}/config/environment"
rescue MissingSourceFile
  if File.exists? "#{File.expand_path(RAILS_ROOT)}/override_config.rb"
    require "#{RAILS_ROOT}/override_config"
  end
end

require 'logger'
logfile = File.expand_path("#{RAILS_ROOT}/log/joyent_calendar_subscriptions.log")
logger = Logger.new(logfile)
logger.info("#{Time.now.to_s}: Calendar Subscriptions synchronization started...")

# Stop for a while once Rails is loaded
sleep(3)

loop do

  begin
  
    cal_subs = CalendarSubscription.find(:all, :conditions => ["update_frequency!='never'"])

    m = 1.month.ago.gmtime
    w = 1.week.ago.gmtime

    cal_subs.each do |cal_sub|
    
        if (cal_sub.update_frequency == 'weekly' && cal_sub.updated_at < w) || (cal_sub.update_frequency == 'monthly' && cal_sub.updated_at < m)
          # localize_time in IcalendarConverter complains if this value is not set
          User.current = cal_sub.owner
          cal_sub.refresh!
          # updated_at value actualized
          cal_sub.save
        end

    end
  
  rescue Exception => e
    raise "#{e.inspect}"
    exit
    logger.error "Exception syncrhonizing calendar subscription with ID=#{cal_sub.id}: #{e}"
  end
  
  logger.info("#{Time.now.to_s}: ... Calendar Subsriptions syncrhonized")
  # wait for a minute and start again, (trying to avoid memory growing without limits)
  sleep(60)
  
end