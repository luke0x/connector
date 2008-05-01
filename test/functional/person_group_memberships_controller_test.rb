require File.dirname(__FILE__) + '/../test_helper'
require 'person_group_memberships_controller'

# Re-raise errors caught by the controller.
class PersonGroupMembershipsController; def rescue_action(e) raise e end; end

class PersonGroupMembershipsControllerTest < Test::Unit::TestCase
  def setup
    @controller = PersonGroupMembershipsController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
  end

  # Replace this with your real tests.
  def test_truth
    assert true
  end
end
