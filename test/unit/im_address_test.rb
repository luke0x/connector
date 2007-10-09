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

class ImAddressTest < Test::Unit::TestCase
  fixtures all_fixtures
  include CRUDTest
  
  crud_data 'person_id'  => 1,
            'preferred'  => true,
            'im_type'    => 'AIM',
            'im_address' => 'jim'

  crud_required 'im_type', 'im_address' #, 'person_id'
            
  def test_sorting
    addresses = people(:ian).im_addresses
    assert_equal im_addresses(:jim), addresses.first
  end
end
