=begin #(fold)
Copyright 2004-2007 Joyent Inc.

Redistribution and/or modification of this code is governed
by either the GPLv2 or Joyent Commercial Software licenses.

Report issues and contribute at http://dev.joyent.com/

$Id$
=end #(end)

require File.dirname(__FILE__) + '/../test_helper'
require 'net/http'

class AddressTest < Test::Unit::TestCase
  fixtures :addresses, :people
  include CRUDTest
  
  crud_data 'person_id'    => 1,
            'preferred'    => true,
            'address_type' => 'Home',
            'street'       => '123 Edgewood',
            'city'         => 'Monroe',
            'state'        => 'MI',
            'postal_code'  => '48161',
            'geocode'      => '',
            'country_name' => 'United States'

  crud_required 'address_type' #, 'person_id'

  def test_geocode_address
    address = assert_create
    assert address.valid?

    assert_equal '123 Edgewood, Monroe, MI 48161', address.geocode_address
  end

  def test_geocode_address_with_no_street
    @test_data['street'] = ''
    address = assert_create
    assert address.valid?

    assert_equal 'Monroe, MI 48161', address.geocode_address
  end

  def test_geocode_address_with_no_city
    @test_data['city'] = ''
    address = assert_create
    assert address.valid?

    assert_equal '123 Edgewood, MI 48161', address.geocode_address
  end

  def test_geocode_address_with_no_state
    @test_data['state'] = ''
    address = assert_create
    assert address.valid?

    assert_equal '123 Edgewood, Monroe, 48161', address.geocode_address
  end

  def test_geocode_address_with_no_postal_code
    @test_data['postal_code'] = ''
    address = assert_create
    assert address.valid?

    assert_equal '123 Edgewood, Monroe, MI', address.geocode_address
  end

  def test_geocode_address_with_no_state_or_postal_code
    @test_data['state'] = ''
    @test_data['postal_code'] = ''
    address = assert_create
    assert address.valid?

    assert_equal '123 Edgewood, Monroe', address.geocode_address
  end

  def test_lat_with_geocode
    @test_data['geocode'] = "41.904409,-83.417912"
    address = assert_create
    
    assert_equal 41.904409, address.lat
  end

  def test_lat_without_geocode
    address = assert_create

    assert_nil address.lat
  end

  def test_long_with_geocode
    @test_data['geocode'] = "41.904409,-83.417912"
    address = assert_create

    assert_equal -83.417912, address.long
  end

  def test_long_without_geocode
    address = assert_create

    assert_nil address.long
  end
  
  def test_get_geocode_address
    # Fake out the http response
    Net::HTTP.module_eval <<-EOS
    require 'ostruct'
    class << self
      alias :orig_get_response :get_response
      def get_response(host, path)
        OpenStruct.new :body => "41.904409,-83.417912,5718 Edgewood Dr,South Monroe,MI,48161\n"
      end
    end
    EOS

    # Kind of a hack, maybe we want getter/setter?
    Address.send(:class_variable_set, :@@geocode_addresses, true)

    address = assert_create
    assert_equal "41.904409,-83.417912", address.geocode

    # Reset hacks
    Net::HTTP.module_eval <<-EOS
    class << self
      alias :get_response :orig_get_response
    end
    EOS
    Address.send(:class_variable_set, :@@geocode_addresses, false)
  end
  
  def test_sorting_rules
    addrs = people(:ian).addresses
    assert_equal addresses(:joyent), addrs.first
  end
  
  def test_blank_address_invalid
    a = Address.create(:person_id => 1, :address_type => 'Home')
    assert a.errors.length > 0

    a = Address.create(:person_id => 1, :address_type => 'Home', :street => '123 Cherry St')
    assert a.errors.empty?

    a = Address.create(:person_id => 1, :address_type => 'Home', :city => 'Springfield')
    assert a.errors.empty?
  end
  
  def test_url_encoded_geocode_address
      @test_data['state'] = ''
      address = assert_create
      assert address.valid?

      assert_equal '123%20Edgewood%2C%20Monroe%2C%2048161', address.url_encoded_geocode_address
  end
end