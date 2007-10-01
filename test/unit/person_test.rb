=begin #(fold)
Copyright 2004-2007 Joyent Inc.

Redistribution and/or modification of this code is governed
by either the GPLv2 or Joyent Commercial Software licenses.

Report issues and contribute at http://dev.joyent.com/

$Id$
=end #(end)

require File.dirname(__FILE__) + '/../test_helper'

class PersonTest < Test::Unit::TestCase
  fixtures all_fixtures
  include CRUDTest

  crud_data 'organization_id' => 1,
            'user_id'         => 1,
            'name_prefix'     => 'Mr.',
            'first_name'      => 'Fred',
            'middle_name'     => 'Quincy',
            'last_name'       => 'Flintstone',
            'name_suffix'     => 'Sr.',
            'nickname'        => 'freddy',
            'company_name'    => 'Bedrock Quarry',
            'title'           => 'Miner',
            'time_zone'       => 'America/Detroit',
            'notes'           => 'Nice guy.'

  crud_required 'organization_id', 'user_id'
  
  def test_user_link
    assert people(:ian).user
    assert ! people(:o1notuser).user
  end
  
  def test_full_name
    assert_equal 'Ian Kevin Curtis', people(:ian).full_name
    assert_equal 'Peter Hook', people(:peter).full_name
  end
  
  def test_admin 
    assert people(:ian).admin?
    assert !people(:peter).admin?
    assert !people(:stephen).admin?
  end
  
  def test_user_email
    assert_equal "ian@textdrive.com", people(:ian).primary_email.email_address
    assert people(:jason).primary_email.blank?
  end
  
  def test_user?
    assert  people(:jason).user?
    assert !people(:notuser).user?
  end
  
  def test_primary_phone
    assert_equal '0800 666 112', people(:ian).primary_phone.phone_number
  end
  
  def test_exportable?
    assert people(:jason).exportable?
    assert !people(:secret_person).exportable?
    assert people(:user_with_restrictions).exportable?
  end

  def search_fixture(name)
    File.read("#{File.dirname(__FILE__)}/../fixtures/search/#{name}.text")
  end
  
  def test_icon
    p = people(:ian)
    assert p.has_icon?
    assert_equal 'jpg', p.icon_type
    assert_equal file_fixture('1/icons/1.jpg'), p.icon
    
    p.remove_icon
    assert !p.has_icon?
    assert_equal nil, p.icon_type
    assert_equal joyent_file_fixture('default-person.png'), p.icon
    
    p.add_icon(file_fixture('1/icons/1.jpg'), 'jpg')
    assert p.has_icon?
    assert_equal 'jpg', p.icon_type
    assert_equal file_fixture('1/icons/1.jpg'), p.icon
  end
  
  def test_single_vcards
    assert_equal vcard_fixture(:ian), people(:ian).to_vcard
    assert_equal vcard_fixture(:peter), people(:peter).to_vcard
    assert_equal vcard_fixture(:chris), people(:chris).to_vcard
  end     
  
  def test_copy
    peter = users(:peter)           
    assert 0, peter.contact_list.people.size
    
    # Copy the ian user to peters contacts
    people(:ian).copy_to(peter.contact_list)
    assert 1, peter.contact_list.people.size
                                     
    contact = peter.contact_list.people.first
     
    assert_equal people(:ian).full_name,      contact.full_name
    assert_equal people(:ian).addresses.size, contact.addresses.size
    assert       people(:ian).has_icon?
    assert       contact.has_icon?
    assert       people(:ian).email_addresses.select{|email| email.email_type == 'Other'}.first.id != contact.email_addresses.select{|email| email.email_type == 'Other'}.first.id
    assert       people(:ian).owner.id != contact.owner.id
  end
  
  def test_destroying_person_destroys_notifications_about_person
    stephen_id = people(:stephen).id
    
    # Ian notifies Peter of Stephen
    users(:peter).notify_of(people(:stephen), users(:ian))
    
    # Peter's notifications should not contain a link to Stephen
    assert users(:peter).current_notifications.map(&:item_id).include?(stephen_id)
    
    # Stephen is deleted
    people(:stephen).destroy
    
    # Peter's notifications should not contain a link to Stephen
    assert !users(:peter).current_notifications(true).map(&:item_id).include?(stephen_id)
  end
  
  def test_changing_name_updates_user_cache
    p = people(:ian)
    p.first_name="OMG"
    p.save!
    assert users(:ian).full_name =~ /OMG/
  end

  def test_admin_can_create_user
    User.current = users(:ian)
    person_params = {'type' => 'user', 'username' => 'anewuser', 'password' => 'pass', 'password_confirmation' => 'pass', 'recovery_email' => 'a@b.com'}

    assert User.current.admin?
    person = people(:stephen)
    assert ! person.user?
    person.update_user_from_params(person_params)
    assert person.reload.user?
  end

  def test_non_admin_cant_create_user
    person_params = {:password => 'pass', :password_confirmation => 'pass', :username => 'anewuser'}
    User.current = users(:peter)
    assert ! User.current.admin?
    person = people(:stephen)
    assert ! person.user?
    person.update_user_from_params(person_params)
    assert ! person.user?
  end
  
  def test_admin_can_change_others_password
  end
  
  def test_non_admin_cant_change_others_password
  end

  def test_non_admin_can_change_own_password
  end

  def test_admin_can_grant_admin
    User.current = users(:ian)
    person_params = {'type' => 'user', 'username' => 'anewuser', 'password' => 'omg', 'password_confirmation' => 'omg', 'recovery_email' => 'a@b.com', 'admin' => 'on'}
    
    assert User.current.admin?
    person = people(:peter)
    assert person.user?
    assert ! person.admin?
    person.update_user_from_params(person_params)
    assert person.admin?
  end
  
  def test_non_admin_cant_grant_admin
    person_params = {:admin => 'on'}
    User.current = users(:peter)
    assert ! User.current.admin?
    person = people(:peter)
    assert person.user?
    assert ! person.admin?
    person.update_user_from_params(person_params)
    assert ! person.admin?
  end
  
  def test_admin_can_revoke_admin_from_others
  end
  
  def test_admin_cant_revoke_admin_from_self
  end

  def test_admin_can_create_guest
    User.current = users(:ian)
    person_params = {'type' => 'guest', 'username' => 'anewuser', 'password' => 'omg', 'password_confirmation' => 'omg', 'recovery_email' => 'a@b.com'}
    person = Person.new
    person.user_id = User.current.id
    person.organization_id = User.current.organization_id
    person.update_user_from_params(person_params)

    assert_equal 0, person.errors.length
    assert person.guest?
  end
  
  def test_extra_stuff_not_made_for_guests
    User.current = users(:ian)
    person_params = {'type' => 'guest', 'username' => 'anewuser', 'password' => 'omg', 'password_confirmation' => 'omg', 'recovery_email' => 'a@b.com'}
    person = Person.new
    person.user_id = User.current.id
    person.organization_id = User.current.organization_id
    person.update_user_from_params(person_params)

    assert_nil person.user.documents_folder
    assert person.user.calendars.empty?
    assert_nil person.user.contact_list
    assert_nil person.user.bookmark_folder
  end

  # def test_regression_for_2918
  #   assert ! users(:peter).admin?
  #   post :edit, {'id' => users(:peter).id, 'person' => {'first_name' => 'Peter', 'last_name' => 'Hook', 'password' => '', 'password_confirmation' => '', 'admin' => 'on', 'time_zone' => 'America/New_York'}}
  #   users(:peter).reload
  # 
  #   assert_response :redirect
  #   assert users(:peter).admin?
  #   post :edit, {'id' => users(:peter).id, 'person' => {'first_name' => 'Peter', 'last_name' => 'Hook', 'password' => '', 'password_confirmation' => '', 'time_zone' => 'America/New_York'}}
  #   users(:peter).reload
  # 
  #   assert ! users(:peter).admin?
  # end  
end