require File.dirname(__FILE__) + '/../test_helper'

class PersonGroupTest < Test::Unit::TestCase
  fixtures :person_groups, :people
  include CRUDTest

  crud_data 'user_id'         => 1,
            'organization_id' => 1,
            'name'            => 'Test Group',
            'created_at'      => (Time.now - 2.days).to_s(:db),
            'updated_at'      => (Time.now - 2.days).to_s(:db)

  crud_required 'user_id', 'organization_id', 'name'  

  # Replace this with your real tests.
  def test_truth
    assert true
  end
  
  
  def test_users
    person_group = person_groups(:empty)
    
    person_group.people << people(:stephen) # just a person
    person_group.people << people(:peter) # this person belongs to a user
    person_group.people << people(:guest) # just a guest
    
    assert person_group.users.include?(people(:peter))
    assert !person_group.users.include?(people(:stephen))
    assert !person_group.users.include?(people(:guest))
  end
  
end
