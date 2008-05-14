require File.dirname(__FILE__) + '/../test_helper'

class PersonGroupTest < Test::Unit::TestCase
  fixtures :person_groups, :people, :users
  include CRUDTest

  crud_data 'user_id'         => 1,
            'organization_id' => 1,
            'name'            => 'Test Group',
            'created_at'      => (Time.now - 2.days).to_s(:db),
            'updated_at'      => (Time.now - 2.days).to_s(:db)

  crud_required 'user_id', 'organization_id', 'name'  

  def test_cascade_permissions
    ian = users(:ian)
    User.current = ian
    pedro = users(:pedro)
    bernard = users(:bernard)
    ian_group = ian.person_groups.create(:name => "Ian's Person Group", :organization_id => ian.organization.id)
    pedro_group = pedro.person_groups.create(:name => "Pedro's Person Group", :organization_id => pedro.organization.id)
    
    ian_group.people << bernard.person
    pedro_group.people << bernard.person
    
    ian_group.make_private!
    
    assert !pedro_group.people(true).include?(bernard.person)
  end
  
  def test_users
    person_group = person_groups(:empty)
    
    person_group.people << people(:stephen) # just a person
    person_group.people << people(:peter) # this person belongs to a user
    person_group.people << people(:guest) # just a guest
    
    assert person_group.users.include?(people(:peter).user)
    assert !person_group.users.include?(people(:stephen).user)
    assert !person_group.users.include?(people(:guest).user)
  end
  
end
