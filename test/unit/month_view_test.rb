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

# Redefine the today method for the Date class in order to test MonthView for various dates
class Date
	@@test_year  = 2008
	@@test_month = 1
	@@test_day   = 1

	def today
		return Date.new(@@test_year, @@test_month, @@test_day)
  end

  def Date.set_test_day(new_year, new_month, new_day)
		@@test_year  = new_year
		@@test_month = new_month
    @@test_day   = new_day
  end
end


class MonthViewTest < Test::Unit::TestCase
	fixtures :users
	START_OF_WEEK = 0

	def setup
		User.current = users(:ian)
	end	

	def test_create_month_view_actual_month
		month_date = Date.new(2008, 03, 01)

		Date.set_test_day(2008, 03, 01)
		assert MonthView.new(month_date, START_OF_WEEK, User.current)
		Date.set_test_day(2008, 03, 15)
		assert MonthView.new(month_date, START_OF_WEEK, User.current)
		Date.set_test_day(2008, 03, 28)
		assert MonthView.new(month_date, START_OF_WEEK, User.current)
	end

	def test_create_month_view_different_month
		month_date = Date.new(2008, 04, 01)

		Date.set_test_day(2008, 03, 01)
		assert MonthView.new(month_date, START_OF_WEEK, User.current)
		Date.set_test_day(2008, 03, 15)
		assert MonthView.new(month_date, START_OF_WEEK, User.current)
		Date.set_test_day(2008, 03, 28)
		assert MonthView.new(month_date, START_OF_WEEK, User.current)
	end
end
