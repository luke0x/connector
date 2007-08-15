=begin #(fold)
Copyright 2004-2007 Joyent Inc.

Redistribution and/or modification of this code is governed
by either the GPLv2 or Joyent Commercial Software licenses.

Report issues and contribute at http://dev.joyent.com/

$Id$
=end #(end)

require File.dirname(__FILE__) + '/../test_helper'

class PhoneNumberTest < Test::Unit::TestCase
  fixtures all_fixtures
  include CRUDTest
  
  crud_data 'person_id'         => 1,
            'preferred'         => true,
            'phone_number_type' => 'Home',
            'phone_number'      => '555-1212'
            
  crud_required 'phone_number_type', 'phone_number' #, 'person_id'

  def test_sorting
    assert_equal 2, people(:ian).phone_numbers.first.id
  end
  
  def test_valid_sms_address
    assert_equal "4155551542@tmomail.net", people(:ian).phone_numbers.find(5).sms_address
  end
end
