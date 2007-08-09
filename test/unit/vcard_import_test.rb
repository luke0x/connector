=begin #(fold)
Copyright 2004-2007 Joyent Inc.

Redistribution and/or modification of this code is governed
by either the GPLv2 or Joyent Commercial Software licenses.

Report issues and contribute at http://dev.joyent.com/

$Id$
=end #(end)

require File.dirname(__FILE__) + '/../test_helper'

class VcardImportTest < Test::Unit::TestCase
  fixtures all_fixtures
  
  def test_address_book_full_contact
    content = vcard_fixture('address_book_full')
    people  = Person.from_vcards(content)
    person  = people.first
    
    assert_equal 1,                            people.size
    assert_equal 'Mr Test Middle User Jr',     person.full_name
    assert_equal 'Joe',                        person.nickname
    assert_equal 'My Company',                 person.company_name
    assert_equal 'Worker Bee',                 person.title
    assert_equal 2,                            person.phone_numbers.size
    assert_equal '(123) 123-1234',             person.phone_numbers.first.phone_number
    assert_equal 'work',                       person.phone_numbers.first.phone_number_type
    assert_equal 2,                            person.addresses.size
    assert_equal 'home',                       person.addresses.last.address_type
    assert_equal "123 Home Street\nPO Box 47", person.addresses.last.street
    assert_equal '12345',                      person.addresses.last.postal_code
    assert_equal 'Your City',                  person.addresses.last.city
    assert_equal 'ST',                         person.addresses.last.state
    assert_equal 2,                            person.email_addresses.size
    assert_equal 'a@b.com',                    person.email_addresses.first.email_address
    assert_equal 'work',                       person.email_addresses.first.email_type
    assert_equal 1,                            person.websites.size
    assert_equal 'www.apple.com',              person.websites.first.site_url
    assert_equal 'homepage',                   person.websites.first.site_title
    assert_equal 1,                            person.special_dates.size
    assert_equal 'Birthdate',                  person.special_dates.first.description
    assert_equal 1,                            person.special_dates.first.special_date.day
    assert_equal 1,                            person.special_dates.first.special_date.month
    assert_equal 2005,                         person.special_dates.first.special_date.year
    assert_equal 4,                            person.im_addresses.size
    assert_equal 'yahooid',                    person.im_addresses.last.im_address
    assert_equal 'Yahoo',                      person.im_addresses.last.im_type
    assert_equal 'Good guy notes',             person.notes
    assert person.has_icon?
  end
  
  def test_address_book_multiple_contacts
    content = vcard_fixture('address_book_multiple')
    people  = Person.from_vcards(content)
    person  = people.first
    
    assert_equal 2,                        people.size
    assert_equal 'Jack Trade',             person.full_name
    assert_equal 'jack@trade.com',         person.email_addresses.first.email_address
  end

  def test_from_joyent_dot_net
    content = vcard_fixture('joyent_dot_net')
    people  = Person.from_vcards(content)
    
    assert_equal 48, people.size
  end                         

  def test_utf16be
    content = vcard_fixture('utf16be')
    people  = Person.from_vcards(content)
    
    assert_equal 1, people.size
  end 

  def test_utf16bebom
    content = vcard_fixture('utf16bebom')
    people  = Person.from_vcards(content)
    
    assert_equal 1, people.size
  end

  def test_entourage_full_contact
    content = vcard_fixture('entourage_full')
    people  = Person.from_vcards(content)
    person  = people.first
    
    assert_equal 1,                        people.size
    assert_equal 'Mr. Chris Morris Jr.',   person.full_name
    assert_equal 'Motown',                 person.nickname
    assert_equal 'Joyent',                 person.company_name
    assert_equal 'Eng',                    person.title
    assert_equal 2,                        person.phone_numbers.size
    assert_equal '555-555-555',           person.phone_numbers.first.phone_number
    assert_equal 'home',                   person.phone_numbers.first.phone_number_type
    assert_equal 2,                        person.addresses.size
    assert_equal 'work',                   person.addresses.first.address_type
    assert_equal '123 Main St',            person.addresses.first.street
    assert_equal '12345',                  person.addresses.first.postal_code
    assert_equal 'Marin',                  person.addresses.first.city
    assert_equal 'CA',                     person.addresses.first.state
    assert_equal 2,                        person.email_addresses.size
    assert_equal 'chris@joyent.com',       person.email_addresses.first.email_address
    assert_equal 'work',                   person.email_addresses.first.email_type
    assert_equal 1,                        person.websites.size
    assert_equal 'www.joyent.com',         person.websites.first.site_url
    assert_equal 'home',                   person.websites.first.site_title
    assert_equal 1,                        person.special_dates.size
    assert_equal 'Birthdate',              person.special_dates.first.description
    assert_equal 8,                        person.special_dates.first.special_date.day
    assert_equal 4,                        person.special_dates.first.special_date.month
    assert_equal 1977,                     person.special_dates.first.special_date.year
    assert_equal 2,                        person.im_addresses.size
    assert_equal 'hits',           person.im_addresses.last.im_address
    assert_equal 'MSN',                    person.im_addresses.last.im_type
    assert_equal 'These are notes',         person.notes
    assert       person.has_icon?
    
    # This is the same icon that is used for the ian user
    assert_equal file_fixture('1/icons/1.jpg'), person.icon
  end

  def test_joyent_full_contact
    content = vcard_fixture('ian')
    people  = Person.from_vcards(content)
    person  = people.first
    
    assert_equal 1,                        people.size
    assert_equal 'Ian Kevin Curtis',       person.full_name
    assert_equal 'ian',                    person.nickname
    assert_equal 'Joy Division',           person.company_name
    assert_equal 'Singer',                 person.title
    assert_equal 4,                        person.phone_numbers.size
    assert_equal '0800 666 112',           person.phone_numbers.first.phone_number
    assert_equal 'mobile',                 person.phone_numbers.first.phone_number_type
    assert       person.phone_numbers.first.preferred
    assert_equal 3,                        person.addresses.size
    assert_equal 'work',                   person.addresses.first.address_type
    assert_equal '14 Kientz Lane',         person.addresses.first.street
    assert_equal '90210',                  person.addresses.first.postal_code
    assert_equal 'San Anselmo',            person.addresses.first.city
    assert_equal 'CA',                     person.addresses.first.state
    assert_equal 'United States',          person.addresses.first.country_name
    assert_equal 3,                        person.email_addresses.size
    assert_equal 'ian@textdrive.com',      person.email_addresses.first.email_address
    assert_equal 'other',                  person.email_addresses.first.email_type
    assert_equal 3,                        person.websites.size
    assert_equal 'http://www.koz.com',     person.websites.first.site_url
    assert_equal 'Koz',                    person.websites.first.site_title
    assert_equal 0,                        person.special_dates.size
    assert_equal 2,                        person.im_addresses.size
    assert_equal 'jim',                  person.im_addresses.first.im_address
    assert_equal 'AIM',                    person.im_addresses.first.im_type
    assert       person.has_icon?
    
    # This is the same icon that is used for the ian user
    assert_equal file_fixture('1/icons/1.jpg'), person.icon
  end

  def test_joyent_multiple_contacts
    # This will use our encoding
    content = vcard_fixture('address_book_multiple')
    people  = Person.from_vcards(VcardConverter.create_vcards_from_people(Person.from_vcards(content)))
    person  = people.first
    
    assert_equal 2,                        people.size
    assert_equal 'Jack Trade',             person.full_name
    assert_equal 'jack@trade.com',         person.email_addresses.first.email_address
  end

#  def test_bogus_vcard
#    content = vcard_fixture('bogus')
#    assert_raise(RuntimeError) {Person.from_vcards(content)}
#  end

end
