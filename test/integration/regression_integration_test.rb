=begin #(fold)
Copyright 2004-2007 Joyent Inc.

Redistribution and/or modification of this code is governed
by either the GPLv2 or Joyent Commercial Software licenses.

Report issues and contribute at http://dev.joyent.com/

$Id$
=end #(end)

require "#{File.dirname(__FILE__)}/../test_helper"

class RegressionIntegration < ActionController::IntegrationTest
  fixtures all_fixtures

  # make sure a person can be created
  def test_regression_for_2634_person
    new_session_as(:ian) do |sess|
      sess.post url_for(:controller => 'people', :action => 'create', 'person[first_name]' => 'A', 'person[last_name]' => 'Person', 'person[type]' => 'contact')

      sess.assert_response :redirect
      sess.follow_redirect!
  
      sess.assert_response :success
      sess.assert Person.find(:first, :conditions => ['first_name = ? and last_name = ?', 'A', 'Person'])
      sess.assert_template 'people/show'
    end
  end

  # make sure a user can be created
  def test_regression_for_2634_user
    new_session_as(:ian) do |sess|
      sess.post url_for(:controller => 'people', :action => 'create', 'person[type]' => 'user', 'person[first_name]' => 'A', 'person[last_name]' => 'User', 'person[username]' => 'user', 'person[password]' => 'user', 'person[password_confirmation]' => 'user', 'person[time_zone]' => 'America/New_York', 'person[recover_email]' => 'a@b.com')

      sess.assert_response :redirect
      sess.follow_redirect!
  
      sess.assert_response :success
      p = Person.find(:first, :conditions => ['first_name = ? and last_name = ?', 'A', 'User'])
      sess.assert p
      sess.assert p.user
      sess.assert_template 'people/show'
    end
  end

  # folders that were being created weren't showing up in the ui
  def test_regression_for_2641
    new_session_as(:ian) do |sess|
      sess.assert ! users(:ian).folders.find_by_name('regression_2641')
      sess.post url_for(:controller => 'files', :action => 'create_folder'), {:group_name => 'regression_2641'}, {'Referer' => '/files/1'}

      sess.assert users(:ian).folders.find_by_name('regression_2641')
      sess.assert_response :redirect
      sess.follow_redirect!

      sess.assert_response :success
      sess.assert sess.response.body =~ /regression_2641/
    end
  end  

end