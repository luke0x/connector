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
require 'comments_controller'

# Re-raise errors caught by the controller.
class CommentsController; def rescue_action(e) raise e end; end

class CommentsControllerTest < Test::Unit::TestCase
  fixtures all_fixtures
  
  def setup
    @controller = CommentsController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
    @request.env['HTTP_REFERER'] = "http://joyent.joyent.com/files"
  end
  
  def test_add_comment_to_item
    comment_count = joyent_files(:ians_dog_jpg).comments.count
    login_person(:ian)
    post :add, :id => joyent_files(:ians_dog_jpg).id, :item_type => 'JoyentFile',
               :body => 'This is a great item.'

    assert_equal comment_count + 1, joyent_files(:ians_dog_jpg).comments(true).count
  end
  
  def test_add_comment_to_item_not_permitted_to_view
    login_person(:peter)
    post :add, :id => joyent_files(:bernards_secret_file).id, :item_type => 'JoyentFile',
               :body => 'This is a great item.'

   assert @response.body.blank?
  end
  
  def test_add_comment_to_non_item_type
    login_person(:peter)
    post :add, :id => joyent_files(:ians_dog_jpg).id, :item_type => 'rm -rf /',
               :body => 'This is a great item.'
               
    assert @response.body.blank?
  end
  
  def test_remove_my_comment
    login_person(:ian)
    post :remove, :id => comments(:ian_comment_ian_jpg).id
    
    assert_nil Comment.find_by_id(comments(:ian_comment_ian_jpg).id)
  end
  
  def test_remove_comment_on_my_item
    login_person(:ian)
    post :remove, :id => comments(:peter_comment_ian_jpg).id
    
    assert_nil Comment.find_by_id(comments(:peter_comment_ian_jpg).id)
  end
  
  def test_cannot_remove_other_comment_on_other_item
    login_person(:peter)
    post :remove, :id => comments(:ian_comment_ian_jpg).id
    
    assert Comment.find_by_id(comments(:ian_comment_ian_jpg).id)
  end
  
  def test_edit_comment
    login_person(:ian)
    post :edit, :id => comments(:ian_comment_ian_jpg).id, :body => 'foo'
    
    assert_equal 'foo', comments(:ian_comment_ian_jpg).reload.body
  end
  
  def test_edit_comment_that_is_not_mine
    login_person(:peter)
    post :edit, :id => comments(:ian_comment_ian_jpg).id, :body => 'foo'
    assert @response.body.blank?
  end

  def test_edit_comment_with_bogus_id
    login_person(:peter)
    post :edit, :id => 54321, :body => 'foo'
    assert @response.body.blank?
  end
end
