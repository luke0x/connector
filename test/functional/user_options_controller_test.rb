=begin #(fold)
Copyright 2004-2007 Joyent Inc.

Redistribution and/or modification of this code is governed
by either the GPLv2 or Joyent Commercial Software licenses.

Report issues and contribute at http://dev.joyent.com/

$Id$
=end #(end)

require File.dirname(__FILE__) + '/../test_helper'
require 'user_options_controller'

# Re-raise errors caught by the controller.
class UserOptionsController; def rescue_action(e) raise e end; end

class UserOptionsControllerTest < Test::Unit::TestCase
  fixtures all_fixtures
  def setup
    @controller = UserOptionsController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
    login_person(:ian)
  end

  def test_set_new_option
    option_count = users(:ian).user_options.length
    assert_nil users(:ian).user_options.find_by_key('yo')

    get :set, {:key => 'yo', :value => 'there'}
    users(:ian).reload
    assert_equal option_count + 1, users(:ian).user_options.length
  end
  
  def test_set_existing_option
    option_count = users(:ian).user_options.length
    assert users(:ian).user_options.find_by_key('Language')
    assert_equal 'en', users(:ian).get_option('Language')

    get :set, {:key => 'Language', :value => 'en'}
    users(:ian).reload
    assert_equal option_count, users(:ian).user_options.length
    assert_equal 'en', users(:ian).get_option('Language')
  end
  
  def test_set_option_invalid
    option_count = users(:ian).user_options.length

    get :set, {:key => '', :value => ''}
    assert_response :success
    assert_equal ' ', @response.body
    users(:ian).reload
    assert_equal option_count, users(:ian).user_options.length
  end
  
end
