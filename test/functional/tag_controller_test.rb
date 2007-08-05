=begin #(fold)
Copyright 2004-2007 Joyent Inc.

Redistribution and/or modification of this code is governed
by either the GPLv2 or Joyent Commercial Software licenses.

Report issues and contribute at http://dev.joyent.com/

$Id$
=end #(end)

require File.dirname(__FILE__) + '/../test_helper'
require 'tag_controller'

# Re-raise errors caught by the controller.
class TagController; def rescue_action(e) raise e end; end

class TagControllerTest < Test::Unit::TestCase
  fixtures all_fixtures
  def setup
    @controller = TagController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
    login_person(:ian)
  end

  def test_auto_complete_multiple_results
    get :auto_complete, {:tag_name => 'ra'}
    assert_tag :tag => 'ul'
    assert_response :success
  end

  def test_auto_complete_single_result
    get :auto_complete, {:tag_name => 'ora'}
    assert_tag :tag => 'ul'
    assert_response :success
  end
  
  def test_auto_complete_nothing
    get :auto_complete
    assert_tag :tag => 'li', :content => ''
  end

  def test_tag_item
    @request.env["HTTP_REFERER"] = '/files'
    get :tag_item, {:dom_ids => joyent_files(:ian_jpg).dom_id, :tag_name => 'floats'}
    assert_response :redirect
    assert joyent_files(:ian_jpg).tags.find_by_name('floats')
  end 
  
  def test_tag_bogus_item
    @request.env["HTTP_REFERER"] = '/files'
    get :tag_item, {:dom_ids => joyent_files(:ian_jpg).dom_id, :tag_name => 'floats'}
    assert_response :redirect
  end
  
  def test_tag_blank_dom_ids
    get :tag_item, {:dom_ids => nil, :tag_name => 'hi'}
    assert_response :redirect

    xhr :get, :tag_item, {:dom_ids => nil, :tag_name => 'hi'}
    assert_response :success
  end
  
  def test_untag_item
    @request.env["HTTP_REFERER"] = '/files'

    get :untag_item, {:dom_ids => joyent_files(:ian_jpg).dom_id, :tag_name => 'orange'}
    assert_response :redirect
    assert ! joyent_files(:ian_jpg).tags.find_by_name('orange')
  end

  def test_untag_blank_dom_ids
    get :untag_item, {:dom_ids => nil, :tag_name => 'hi'}
    assert_response :redirect

    xhr :get, :untag_item, {:dom_ids => nil, :tag_name => 'hi'}
    assert_response :success
  end
end