=begin #(fold)
Copyright 2004-2007 Joyent Inc.

Redistribution and/or modification of this code is governed
by either the GPLv2 or Joyent Commercial Software licenses.

Report issues and contribute at http://dev.joyent.com/

$Id$
=end #(end)

require File.dirname(__FILE__) + '/../test_helper'

class ReportDescriptionTest < Test::Unit::TestCase
  fixtures all_fixtures
  include CRUDTest

  crud_data     'name' => 'report' 
  crud_required 'name'
                      
  def test_uniqueness
    assert_equal 1, ReportDescription.count(:conditions => ["name = 'calendar'"])
    ReportDescription.create(:name => 'calendar')
    assert_equal 1, ReportDescription.count(:conditions => ["name = 'calendar'"])
  end                            
  
  def test_valid_fetcher
    assert_equal 0, ReportDescription.count(:conditions => ["name = 'asdf'"])
    ReportDescription.create(:name => 'asdf')
    assert_equal 0, ReportDescription.count(:conditions => ["name = 'asdf'"])
  end
end
