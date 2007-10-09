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

class ContactListTest < Test::Unit::TestCase
  fixtures :contact_lists, :users, :organizations, :people
  include CRUDTest

  crud_data 'user_id'         => 1,
            'organization_id' => 1

  crud_required 'user_id', 'organization_id'

  def test_build_person_sets_associations
    attrs = {'name_prefix'     => 'Mr.',
             'first_name'      => 'Fred',
             'middle_name'     => 'Quincy',
             'last_name'       => 'Flintstone',
             'name_suffix'     => 'Sr.',
             'nickname'        => 'freddy',
             'company_name'    => 'Bedrock Quarry',
             'title'           => 'Miner',
             'time_zone'       => 'America/Detroit',
             'notes'           => 'Nice guy.'}
             
    cl = users(:ian).contact_list
    
    person = cl.build_person(attrs)
    assert person.save
    assert_equal users(:ian), person.owner
    assert_equal organizations(:joyent), person.organization
    assert_equal cl, person.contact_list
    assert organizations(:joyent).people(person)
  end

  def test_cascade_permissions
    User.current = users(:ian)

    assert contact_lists(:ian).permissions.empty?
    assert contact_lists(:ian).people.first.permissions.empty?
    
    contact_lists(:ian).restrict_to!([users(:ian)])
    assert_equal 1, contact_lists(:ian).permissions.length
    assert_equal users(:ian), contact_lists(:ian).permissions.first.user
    assert_equal 1, contact_lists(:ian).people.first.permissions.length
    assert_equal users(:ian), contact_lists(:ian).people.first.permissions.first.user
  end
end
