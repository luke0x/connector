=begin #(fold)
Copyright 2004-2007 Joyent Inc.

Redistribution and/or modification of this code is governed
by either the GPLv2 or Joyent Commercial Software licenses.

Report issues and contribute at http://dev.joyent.com/

$Id$
=end #(end)

require File.dirname(__FILE__) + '/../test_helper'

class SpecialDateTest < Test::Unit::TestCase
  fixtures all_fixtures
  include CRUDTest
  
  crud_data 'person_id'    => 1,
            'preferred'    => true,
            'description'  => "Scott's Birthday",
            'special_date' => '1976-02-24'

  crud_required 'description', 'special_date' #, 'person_id'
  
  def test_year
    item = assert_create
    
    assert_equal 1976, item.special_date.year
  end

  def test_month
    item = assert_create
    
    assert_equal 2, item.special_date.month
  end

  def test_day
    item = assert_create
    
    assert_equal 24, item.special_date.day
  end
  
  def test_sorting
    assert_equal 2, people(:ian).special_dates.first.id
  end
end
