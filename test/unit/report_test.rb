=begin #(fold)
Copyright 2004-2007 Joyent Inc.

Redistribution and/or modification of this code is governed
by either the GPLv2 or Joyent Commercial Software licenses.

Report issues and contribute at http://dev.joyent.com/

$Id$
=end #(end)

require File.dirname(__FILE__) + '/../test_helper'

class ReportTest < Test::Unit::TestCase
  fixtures all_fixtures
  include CRUDTest

  crud_data 'report_description_id' => 12,
            'reportable_id'         => 1,
            'reportable_type'       => 'Folder',
            'position'              => 3,
            'organization_id'       => 1,
            'user_id'               => 1
            
  crud_required 'report_description_id', 
                'reportable_id', 
                'reportable_type', 
                'organization_id', 
                'user_id'
                
  def test_reportable_type
    pre_count = Report.count
    Report.create(:report_description_id => 12,
                  :reportable_id         => 1,
                  :reportable_type       => 'User',
                  :organization_id       => 1,
                  :user_id               => 1)
         
    assert_equal pre_count, Report.count
  end
end
