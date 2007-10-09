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
require 'people_controller'

# Re-raise errors caught by the controller.
class PeopleController; def rescue_action(e) raise e end; end

class PeopleControllerTest < Test::Unit::TestCase
  fixtures all_fixtures

  def setup
    @controller = PeopleController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
  end

  def test_index_works
    login_person(:ian)
    get :index
    assert_response :redirect
    assert_redirected_to people_list_url(:group => users(:ian).contact_list.id)
  end

  def test_empty_create_works
    login_person(:ian)
    get :create

    assert assigns(:person)
    assert assigns(:person).new_record?
    assert_response :success
#    assert_select 'input#person_account_type[value=?]', /admin|user|guest|contact/
    assert_template 'edit'
  end

  def test_person_create_works
    login_person(:ian)
    post :create, {:person => {:type => 'contact', :first_name => 'a'},
      :new_item_notifications => users(:ian).dom_id, :new_item_permissions => users(:ian).dom_id, :new_item_tags => 'huh'}

    assert assigns(:person)
    assert_equal false, assigns(:person).new_record?
    assert_response :redirect

    assert_equal 1, assigns(:person).notifications.length
    assert_equal 1, assigns(:person).users_with_permissions.length
    assert_equal 1, assigns(:person).tags.length
  end
  
  def test_person_create_with_associations
    login_person(:ian)
    post :create, {:new_item_notifications => '', :new_item_permissions => '', :new_item_tags => '',
      :person => {:type => 'contact', :first_name => 'New', :last_name => 'Contact',
        :phone_numbers => { '0' => {'phone_number_type' => 'Home', 'phone_number' => '555-1212'} },
        :email_addresses => { '0' => {'email_type' => 'Home', 'email_address' => 'jill@joyent.com'} },
        :addresses => { '0' => {'address_type' => 'Home', 'street' => 'wherever'} },
        :im_addresses => { '0' => {'im_type' => 'Home', 'im_address' => 'joyent_jill'} },
        :websites => { '0' => {'site_title' => 'Joyent Homepage', 'site_url' => 'http://joyent.com'} },
        :special_dates => { '0' => {'description' => 'A new year', 'day' => '1', 'month' => '1', 'year' => '2007'} }
      }
    }
    
    assert assigns(:person)
    assert_equal false, assigns(:person).new_record?
    assert_equal 1, assigns(:person).phone_numbers.length
    assert_equal 1, assigns(:person).email_addresses.length
    assert_equal 1, assigns(:person).addresses.length
    assert_equal 1, assigns(:person).im_addresses.length
    assert_equal 1, assigns(:person).websites.length
    assert_equal 1, assigns(:person).special_dates.length
  end
                                       
  def test_contacts_list_works
    login_person(:ian)
    get :list, {:group => User.current.contact_list.id}
    test_list_common
    assert_toolbar([:new, :copy, :delete, :import])      
  end    
  
  def test_contacts_list_ajax
    login_person(:ian)
    xhr :get, :list, {:group => User.current.contact_list.id} 
    test_list_common_ajax
  end

  def test_contacts_show_works
    login_person(:ian)
    get :show, {:id => people(:stephen).id}
    test_show_common
    assert_template 'show'
    assert_toolbar([:new, :edit, :copy, :delete, :import])
  end        
  
  def test_show_others_contact 
    login_person(:peter) 
    get :show, {:id => people(:stephen).id}
    test_show_common
    assert_template 'show'
    assert_toolbar([:new, :copy, :import])
  end

  def test_contacts_vcards_works
    login_person(:ian)
    get :vcards, {:group => User.current.contact_list.id}
    test_vcards_common
  end

  def test_contacts_edit_works
    login_person(:ian)
    get :edit, {:id => 1}
    test_edit_common
  end

  def test_contacts_delete_works
    login_person(:ian)
    @request.env["HTTP_REFERER"] = '/people/'
    get :delete, {:ids => 1}
    test_delete_common
  end

  def test_users_list_works
    login_person(:ian)
    get :list, :group => 'users'
    test_list_common
    assert_toolbar([:quota, :new, :copy, :delete, :import])
  end 
  
  def test_users_list_ajax
    login_person(:ian)
    xhr :get, :list, :group => 'users'
    test_list_common_ajax
  end

  def test_users_show_works
    login_person(:ian)
    get :show, :id => people(:ian).id
    test_show_common
    assert_template 'show'                               
    # Delete button is not present for your own record
    assert_toolbar([:quota, :new, :edit, :copy, :import])
    
    get :show, :id => people(:stephen).id
    test_show_common
    assert_template 'show'

    # Delete is present for other users when you are an admin
    assert_toolbar([:new, :edit, :delete, :copy, :import])
  end

  def test_users_vcards_works
    login_person(:ian)
    get :vcards, :group => 'users'
    test_vcards_common
  end

  def test_users_edit_works
    login_person(:ian)
    get :edit, :id => 1
    test_edit_common
  end

#  def test_users_delete_works
#    @request.env["HTTP_REFERER"] = '/people/'
#    get :delete, :ids => 1
#    test_delete_common
#    assert_redirected_to people_delete_confirm_url(:ids => '1')
#  end

  def test_all_notifications
    login_person(:ian)
    get :notifications, {:all => ''}

    assert_response :success
    assert assigns(:notifications)
    assert_toolbar([:new_notifications])
  end

  def test_notifications
    login_person(:ian)
    get :notifications
    assert assigns(:notifications)
    assert_toolbar([:all_notifications])
  end

  def test_notifications_ajax
    login_person(:ian)
    xhr :get, :notifications      
    assert assigns(:notifications)
    assert :success
  end
  
  def test_show_works
    login_person(:ian)
    get :show, :id => people(:stephen).id
    test_show_common
    assert_template 'show'  
    assert_toolbar([:new, :edit, :copy, :delete, :import])
  end   
  
  def test_smart_list_ajax
    login_person(:ian)
    xhr :get, :list, :group => 's9'
    test_list_common_ajax
  end

  def test_notifications_vcards_works
    login_person(:ian)
    get :vcards, :group => 'notifications'
    test_vcards_common
  end

  def test_smart_list_works
    login_person(:ian)
    get :list, :group => 's9'
    test_list_common           
    assert_toolbar([:new, :copy, :delete, :import])
  end
   
  # Regression for ticket 3368                        
  def test_smart_list_works_with_nils   
    login_person(:ian)
    users(:ian).contact_list.people.create(:first_name => "Test", :organization_id => organizations(:joyent).id, :user_id => users(:ian).id)
    smart_groups(:ian_people_body_foo).update_attribute(:tags, 'foo')
    people(:stephen).update_attribute(:last_name, nil)     
    get :list, :group => 's9'
    test_list_common           
    assert_toolbar([:new, :copy, :delete, :import])
  end
  
  def test_smart_show_works
    login_person(:ian)
    get :show, :id => people(:stephen).id
    test_show_common
    assert_template 'show'   
    assert_toolbar([:new, :edit, :copy, :delete, :import])
  end

  def test_smart_vcards_works
    login_person(:ian)
    get :vcards, :group => 's9'
    test_vcards_common
  end

  def test_edit_works
    login_person(:ian)
    get :edit, :id => 1
    test_edit_common
  end

  def test_smart_delete_works
    login_person(:ian)
    @request.env["HTTP_REFERER"] = '/people/'
    get :delete, :ids => 1
    test_delete_common
  end

  def test_vcard_works
    login_person(:ian)
    get :vcard, :id => 1
    assert assigns(:person)
    assert_response :success
  end         
  
  def test_vcard_works_with_nil
    login_person(:ian)
    people(:ian).update_attribute(:last_name, nil)
    get :vcard, :id => 1                             
    assert assigns(:person)
    assert_response :success
  end                         
  
  def test_icon_works
    login_person(:ian)
    get :icon, :id => 1
    assert assigns(:person)
    assert_response :success
  end

  def test_comments_show
    login_person(:ian)
    get :show, {:id => people(:ian).id}
    assert_response :success
    assert @response.body =~ /<div id="comments" class="CommentsCollapsed">/
  end
  
  def test_comments_dont_show
    login_person(:ian)
    xml_http_request :post, :show, {:id => people(:ian).id}
    assert_response :success
    assert (@response.body =~ /<div id="comments" class="CommentsCollapsed">/).blank?
  end
  
  def test_cant_delete_person_outside_org
    login_person(:ian)
    assert Person.find(people(:notuser).id)
    @request.env["HTTP_REFERER"] = '/people/'
    get :delete, {:ids => people(:notuser).id}
    assert Person.find(people(:notuser).id)
  end

  def test_call
    call_count = users(:ian).calls.count
    login_person(:ian)
    xhr :get, :call, {:jajah_username => 'ian@ian.com', 
                      :jajah_password => 'ian', 
                      :jajah_from_number => '1231231234',
                      :jajah_to_numbers => [4]}
    
    assert_response :success
    assert_equal "Dialing...", flash[:status]
    assert_equal call_count + 1, User.find(1).calls.count
    
    call = User.find(1).calls[0]
    assert call.successful?
    assert_equal 1, call.status_code
    assert_equal 1, call.callings.count
    assert_equal phone_numbers(:four).phone_number, call.callings.first.phone_number
  end
  
  def test_call_bad_name
    call_count = users(:ian).calls.count
    login_person(:ian)
    xhr :get, :call, {:jajah_username => 'badname', 
                      :jajah_password => 'ian', 
                      :jajah_from_number => '1231231234',
                      :jajah_to_numbers => [4]}
    
    assert_response :success
    assert_equal "Could not complete call (Invalid username or password.)", flash[:status]
    assert_equal call_count + 1, User.find(1).calls.count
    
    call = User.find(1).calls[0]
    assert !call.successful?
    assert_equal -1, call.status_code
    assert_equal 1, call.callings.count
    assert_equal phone_numbers(:four).phone_number, call.callings.first.phone_number
  end
  
  def test_call_multiperson
    call_count = users(:ian).calls.count
    login_person(:ian)
    xhr :get, :call, {:jajah_username => 'ian', 
                      :jajah_password => 'ian', 
                      :jajah_from_number => '1231231234',
                      :jajah_to_numbers => [4, 3]}
    
    assert_response :success
    assert_equal "Dialing...", flash[:status]
    assert_equal call_count + 1, User.find(1).calls.count
    
    call = User.find(1).calls[0]
    assert call.successful?
    assert_equal 1, call.status_code
    assert_equal 2, call.callings.count
    assert_equal phone_numbers(:four).phone_number, call.callings.last.phone_number
    assert_equal phone_numbers(:three).phone_number, call.callings.first.phone_number
  end
  
  def test_call_list
    login_person(:ian)
    xhr :get, :call_list, {:ids => "1,2"}
    
    assert_response :success
  end
  
  def test_call_list
    login_person(:ian)
    xhr :get, :call_list, {:id => "1"}
    
    assert_response :success
  end
  
  def test_jajah_info
    login_person(:ian)
    xhr :get, :get_jajah_info, {:jajah_username => 'ian', :jajah_password => 'ian'}
    assert_response :success
    assert_equal  "Valid login.", flash[:status]
    
    xhr :get, :get_jajah_info, {:jajah_username => 'ian'}
    assert_response :success
    assert_equal  "Empty Jajah credentials.", flash[:status]
  end
  
#  def test_show_redirects_on_failure
#    fake_id = 999999999
#    assert Person.find_by_id(fake_id).blank?
#    get :show, {:item => fake_id}
#    assert_redirected_to people_home_url
#  end

  # person peek view wasn't in place yet
  def test_regression_for_2626
    login_person(:ian)
    xml_http_request :post, :show, {:id => people(:ian).id}
    test_show_common
    assert_template '_peek'
  end

  # url to delete contact was wrong
  def test_regression_for_2627_html
    login_person(:ian)
    get :list, {:group => users(:ian).contact_list.id}
    l = people_delete_url
    assert @response.body =~ /#{l}/
  end
  
  # make sure deleting a person actually works
  def test_regressions_for_bug_2627_delete
    login_person(:ian)
    assert Person.find(people(:o1notuser).id)
    @request.env["HTTP_REFERER"] = '/people/'
    post :delete, {:ids => people(:o1notuser).id}
    
    assert Person.find_by_id(people(:o1notuser).id).blank?
    assert_response :redirect
  end

  def test_regression_for_2632
    login_person(:ian)
    get :vcard, {:id=>people(:peter).id}
    assert_response :success
    peeps = VcardConverter.create_people_from_vcards(@response.body)
    assert_equal 1, peeps.size
    assert_equal peeps.first.first_name, people(:peter).first_name
  end
  
  def test_regression_for_2633
    login_person(:ian)
    get :edit, {:id => 1}
    test_edit_common
    # Not sure why this is commented out
#    assert_tag :input, :attributes => {:type => "submit", :value => "Save"}
  end

  # import vcard wasn't tested
  def test_regression_for_2773                                    
    login_person(:ian)
    @request.env["HTTP_REFERER"] = "/foo"
    get :list, {:group => User.current.contact_list.id}
    assert assigns(:people)
    assert 1, assigns(:people).size    
   
    post :import, :vcard => fixture_file_upload('/vcards/address_book_multiple.vcf', 'text/plain')
    assert_response :redirect   
    assert assigns(:people)
    assert 3, assigns(:people).size 
  end

  # make sure users can view other users' smart groups
  def test_regression_for_2801
    login_person(:ian)
    assert_not_equal User.current, smart_groups(:peter_people_tagged_foo).owner
    get :list, :group => smart_groups(:peter_people_tagged_foo).url_id
    test_list_common
    assert_toolbar([:new, :copy, :import])
  end

  # make sure form posting can toggle a user's admin status
  def test_regression_for_2918
    login_person(:ian)
    assert ! users(:peter).admin?
    post :edit, {'id' => users(:peter).id, 'person' => {'first_name' => 'Peter', 'last_name' => 'Hook', 'password' => '', 'password_confirmation' => '', 'admin' => 'on', 'time_zone' => 'America/New_York'}}
    users(:peter).reload

    assert_response :redirect
    assert users(:peter).admin?
    post :edit, {'id' => users(:peter).id, 'person' => {'first_name' => 'Peter', 'last_name' => 'Hook', 'password' => '', 'password_confirmation' => '', 'time_zone' => 'America/New_York'}}
    users(:peter).reload

    assert ! users(:peter).admin?
  end

  # didn't have the form url correct
  def test_regression_for_3227
    login_person(:ian)
    get :list, { :group => 'users' }
    assert @response.body =~ /#{people_import_url}/
  end

  def test_users_list_has_usage_doohickey
    login_person(:ian)
    get :list, :group => 'users'
    assert_response :success
    assert @response.body =~ /#{User.current.organization.users.length}\/100 Users Created/
    assert @response.body =~ /<strong class="bar" style="width: #{User.current.organization.users.length}%;"><\/strong>/
  end
  
  def test_smart_group_attributes
    login_person(:ian)
    get :list, :group => 'users'
    assert_response :success
    assert_smart_group_attributes_assigned smart_group_descriptions(:people)
  end

  def test_delete_people
    login_person(:ian)
    @request.env["HTTP_REFERER"] = '/people/' + User.current.contact_list.id.to_s
    ids = [people(:stephen).id, people(:o1notuser).id] * ','
    post :delete, {:ids=>ids}
    assert_redirected_to people_list_url(:group => users(:ian).contact_list.id)
  end                          
  
  def test_copy_person  
    login_person(:ian)
    get :list, {:group => User.current.contact_list.id}
    assert assigns(:people)
    assert 1, assigns(:people).size
    
    ids=[people(:stephen).id, people(:peter).id]*','        
    post :copy, {:ids => ids}       
    assert_response :redirect   
    assert assigns(:people)
    assert 3, assigns(:people).size
  end
  
  def test_peek
    login_person(:ian)
    xhr :get, :show, {:id => people(:ian).id}
    assert_response :success
    assert_template '_peek'
  end
  
  def test_preview_user   
    login_person(:ian)
    xhr :post, :show, :id => 1
                                                                              
    test_show_common
    assert_template '_peek'                                                   
  end
  
  def test_preview_contact 
    login_person(:ian)
    xhr :post, :show, {:id => 1}
                           
    test_show_common
    assert_template '_peek'
  end 
  
  # Regression for 2887
  # Can't delete people you don't own
  def test_non_owner_delete_contacts_list
    login_person(:peter)
    @request.env["HTTP_REFERER"] = '/people/'
    assert Person.find(people(:stephen).id)
    get :delete, {:ids => people(:stephen).id}
    assert Person.find(people(:stephen).id)
  end
                                     
  # Regression for 2887
  # Can't delete people you don't own
  def test_non_owner_delete_smart_group
    login_person(:peter)
    @request.env["HTTP_REFERER"] = '/people/'
    assert Person.find(people(:stephen).id)
    get :delete, {:ids => people(:stephen).id}
    assert Person.find(people(:stephen).id)
  end  
                    
  # Regression for 3040
  def test_edit_user
    login_person(:peter)
    u = users(:peter)
    u.admin = false
    u.save
    get :edit, :id => u.id
    test_edit_common  
  end

  def test_set_sort_order
    login_person(:ian)
    @request.env["HTTP_REFERER"] = '/people/1'
    assert_nil User.current.get_option('People Sort Field')
    assert_nil User.current.get_option('People Sort Order')
    get :set_sort_order, :sort_field => @controller.send(:valid_sort_fields).first, :sort_order => 'ASC'

    assert_response :redirect
    assert_equal User.current.get_option('People Sort Field'), @controller.send(:valid_sort_fields).first
    assert_equal User.current.get_option('People Sort Order'), 'ASC'
  end
  
  def test_others_groups
    login_person(:ian)
    xhr :get, :others_groups, :user_id => users(:peter).id
    assert_response :success
  end   
     
  def test_current_time
    login_person(:ian)
    get :current_time        
    assert assigns(:people)            
    assert_response :success
    assert_layout
  end                  
  
  def test_current_time_ajax
    login_person(:ian)
    xhr :get, :current_time   
    assert assigns(:people)                 
    assert_response :success
    assert_no_layout
  end
  
  # Copied from:
  # http://newbieonrails.topfunky.com/articles/2006/02/01/rjs-and-content-type-header
  def test_rjs_header
    login_person(:ian)
    xhr :get, :show, :id => 1    
    assert_equal @response.headers['Content-Type'], 'text/javascript; charset=UTF-8'
  end

  def test_normal_header
    login_person(:ian)
    get :show, :id => 1    
    assert_equal @response.headers['Content-Type'].downcase, 'text/html; charset=UTF-8'.downcase # huh
  end
 
  # Regression test for case: 4062
  def test_admin_deletes_user_with_comment_on_non_owned_item
    login_person(:ian)
    post :delete, {:ids => 2}

    assert_nil User.find_by_username('peter')
  end

  private

    def test_list_common_ajax
      assert assigns(:group_name)
      assert assigns(:people)
      assert_template '_people'
      assert_response :success  
    end

    def test_list_common
      assert assigns(:group_name)
      assert assigns(:people)
      assert_template 'list'
      assert_response :success 
    end

    def test_show_common
      assert assigns(:group_name)
      assert assigns(:person)
      assert_response :success
    end

    def test_vcards_common
      assert assigns(:people)
      assert_response :success
      assert_equal @response.headers['Content-Type'], 'application/octet-stream'
    end

    def test_edit_common
      assert assigns(:group_name)
      assert assigns(:person)
      assert_response :success
    end

    def test_delete_common
      assert_response :redirect
    end                      

end
