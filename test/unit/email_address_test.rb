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

class EmailAddressTest < Test::Unit::TestCase
  fixtures all_fixtures
  include CRUDTest
  
  crud_data 'person_id'     => 1,
            'preferred'     => true,
            'email_type'    => 'Home',
            'email_address' => 'foo@bar.com'

  crud_required 'email_type', 'email_address' #, 'person_id'

  def test_sorting
    addresses = people(:ian).email_addresses
    assert_equal 2, addresses.first.id
  end
end