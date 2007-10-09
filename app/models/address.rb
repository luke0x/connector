=begin #(fold)
++
Copyright 2004-2007 Joyent Inc.

Redistribution and/or modification of this code is 
governed by the GPLv2.

Report issues and contribute at http://dev.joyent.com/

$Id$
--
=end #(end)

class Address < ActiveRecord::Base
#  validates_presence_of :person_id
  validates_presence_of :address_type

  belongs_to  :person

  before_save :set_geocode
  after_save {|record| record.person.save if record.person}
  after_destroy {|record| record.person.save if record.person}

  @@geocode_addresses = false

  def geocode_address
    address_array = [street, city]
    address_array << [state, postal_code].reject(&:blank?) * ' '
    address_array.reject(&:blank?) * ', '
  end

  def lat
    latitude = self.geocode.split(',').first
    latitude.blank? ? nil : latitude.to_f
  end

  def long
    longitude = self.geocode.split(',').last
    longitude.blank? ? nil : longitude.to_f
  end
  
  def url_encoded_geocode_address
    ERB::Util.url_encode(geocode_address)
  end
  
  protected

    def validate
      errors.add(nil, "The address can not be entirely blank") if (street.to_s + city.to_s + state.to_s + postal_code.to_s + country_name.to_s).strip.blank?
    end

    # turns an address string into an array of lat/long strings
    def get_geocode_address
      host = 'rpc.geocoder.us'
      path = '/service/csv?address='

      response = Net::HTTP.get_response(host, path + ERB::Util.url_encode(self.geocode_address))

      location = response.body.split(',')[0..1]
      location
    end
  
    def set_geocode
      self.geocode = get_geocode_address.join(',') if @@geocode_addresses
    end
end