=begin #(fold)
Copyright 2004-2007 Joyent Inc.

Redistribution and/or modification of this code is governed
by either the GPLv2 or Joyent Commercial Software licenses.

Report issues and contribute at http://dev.joyent.com/

$Id$
=end #(end)

require File.dirname(__FILE__) + '/../test_helper'
require 'syndication_controller'
require 'flexmock'

# Re-raise errors caught by the controller.
class SyndicationController; def rescue_action(e) raise e end; end

FV = "python " + File.dirname(__FILE__) + '/../feedvalidator/fv.py'

# courtesey of typo, we now have feed validation in our tests

if($validator_installed == nil)
  $validator_installed = false
  begin
    IO.popen("#{FV} 2> /dev/null","r") do |pipe|
      if (pipe.read =~ %r{Validating http://www.intertwingly.net/blog/index.})
        puts "Using locally installed Python feed validator"
        $validator_installed = true
      end
    end
  rescue
    nil
  end
end

# Fux it
class Message < ActiveRecord::Base
  def body
    ''
  end
  
  def multipart?
    false
  end
  
  def display_structure
    [['utf8', '']]
  end
end

class SyndicationControllerTest < Test::Unit::TestCase
  include FlexMock::TestCase
  
  fixtures all_fixtures
  def setup
    @controller = SyndicationController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
    http_login_person(:ian)
  end

  def test_standard_calendar_rss
    get :standard_calendar_rss, {:calendar_id=>calendars(:concerts).id}
    assert_response :success
    assert assigns(:events)
    rss_common_assertions
  end
      
  def test_others_standard_calendar_rss 
    http_login_person(:peter)
    get :standard_calendar_rss, {:calendar_id=>calendars(:concerts).id}
    assert_response :success
    assert assigns(:events)
    rss_common_assertions
  end
  
  def test_smart_calendar_rss
    get :smart_calendar_rss, {:smart_group_id => smart_groups(:ian_foo_events).url_id}
    assert_response :success
    assert assigns(:events)
    rss_common_assertions
  end
     
  def test_others_smart_calendar_rss
    http_login_person(:peter)
    get :smart_calendar_rss, {:smart_group_id => smart_groups(:ian_foo_events).url_id}
    assert_response :success
    assert assigns(:events)
    rss_common_assertions
  end
  
  def test_notifications_calendar_rss
    get :notifications_calendar_rss, {}
    assert_response :success
    assert assigns(:events)
    rss_common_assertions
  end
  
  def test_all_calendar_rss
    get :all_calendar_rss, {}
    assert_response :success
    assert assigns(:events)
    rss_common_assertions
  end
  
  def test_all_calendar_ics
    get :all_calendar_ics, {}
    assert_response :success
    assert assigns(:events)
    assert assigns(:group_name)
  end                      
  
  def test_standard_calendar_ics
    get :standard_calendar_ics, {:calendar_id=>calendars(:concerts).id}
    assert_response :success
    assert assigns(:events)
    assert assigns(:group_name)
  end
      
  def test_others_standard_calendar_ics 
    http_login_person(:peter)
    get :standard_calendar_ics, {:calendar_id=>calendars(:concerts).id}
    assert_response :success
    assert assigns(:events)
    assert assigns(:group_name)
  end
  
  def test_smart_calendar_ics
    get :smart_calendar_ics, {:smart_group_id => smart_groups(:ian_foo_events).url_id}
    assert_response :success
    assert assigns(:events)
    assert assigns(:group_name)
  end
     
  def test_others_smart_calendar_ics
    http_login_person(:peter)
    get :smart_calendar_ics, {:smart_group_id => smart_groups(:ian_foo_events).url_id}
    assert_response :success
    assert assigns(:events)
    assert assigns(:group_name)
  end
  
  def test_notifications_calendar_ics
    get :notifications_calendar_ics, {}
    assert_response :success
    assert assigns(:events)
    assert assigns(:group_name)
  end
  
  
  def test_contacts_rss_works
    get :people_rss, {:group => users(:ian).contact_list.id}
    rss_common_assertions
  end
  
  def test_users_rss_works
    get :people_rss, {:group => 'users'}
    rss_common_assertions
  end
  
  def test_notifications_rss_works
    get :people_rss, {:group => 'notifications'}
    rss_common_assertions
  end
  
  def test_smart_rss_works
    get :people_rss, :group => 's9'
    rss_common_assertions
  end


  def test_mail_mailbox_works
    flexmock(Mailbox).should_receive(:list).returns([])
    flexmock(Mailbox).new_instances.should_receive(:sync)
    
    get :mail_mailbox_rss, :id=>mailboxes(:ian_inbox).id
    assert_response :success
    rss_common_assertions
  end
  
  def test_mail_smart_works
    flexmock(Mailbox).should_receive(:list).returns([])
    flexmock(Mailbox).new_instances.should_receive(:sync)
    
    get :mail_smart_rss, :smart_group_id => smart_groups(:ian_foo_mail).url_id
    assert_response :success
    rss_common_assertions
  end 
 
  def test_mail_notifications_works
    flexmock(Mailbox).should_receive(:list).returns([])
    flexmock(Mailbox).new_instances.should_receive(:sync)
    
    get :mail_notifications_rss
    assert_response :success
    rss_common_assertions
  end      
  
  def test_files_standard_rss
    get :files_standard_rss, :folder_id => folders(:ian_pictures).id
    assert_response :success
    rss_common_assertions  
  end                        
  
  def test_files_smart_rss
    get :files_smart_rss, :smart_group_id => smart_groups(:ian_files).url_id
    assert_response :success
    rss_common_assertions  
  end                     
  
  def test_files_notifications_rss
    get :files_notications_rss
    assert_response :success
    rss_common_assertions  
  end                             
  
  def test_connect_smart_rss
    get :connect_smart_rss, :smart_group_id => smart_groups(:ian_everything_from_peter).url_id
    assert_response :success
    rss_common_assertions  
  end                       
  
  def test_connect_notifications_rss   
    get :connect_notifications_rss
    assert_response :success
    rss_common_assertions  
  end   
    
  def test_current_time_rss
    get :current_time_rss, {:id => 1}
    assert_response :success
    rss_common_assertions  
  end                      
  
  def test_recent_comments_rss
    get :recent_comments_rss, {:id => 1}
    assert_response :success
    rss_common_assertions  
  end                         
  
  def test_unread_messages_rss
    flexstub(JoyentMaildir::Base).should_receive(:connection).returns {
      flexmock('connection') {|m|
        m.should_receive(:mailbox_sync)
      }
    }
    
    get :unread_messages_rss, {:id => 1}
    assert_response :success
    rss_common_assertions  
  end                         
  
  def test_todays_events_rss
    get :todays_events_rss, {:id => 1}
    assert_response :success
    rss_common_assertions  
  end                       
  
  def test_weeks_events_rss
    get :weeks_events_rss, {:id => 1}
    assert_response :success
    rss_common_assertions  
  end

  def test_tag_rss
    get :tag_rss, :tag_name => tags(:orange).name
    assert_response :success
    rss_common_assertions  
  end       
  
  def test_tag_rss_unknown
    get :tag_rss, :tag_name => 'asdfasdf'
    assert_response :success
    rss_common_assertions                
    assert_equal assigns(:items).size, 0
  end          
  
  def test_bookmarks_smart_folder
    http_login_person(:ian)
    get :bookmarks_smart_list_rss, {:smart_group_id => smart_groups(:ian_secure_bookmarks).url_id}
    assert_response :success
    assert assigns(:bookmarks)
    assert assigns(:group_name)
  end
  
  def rss_common_assertions
    assert_response :success
    assert_xml @response.body
    assert_feedvalidator(@response.body)
  end
  
  def test_lists_standard_rss
    # get :lists_standard_rss, :group_id => list_folders(:ian_silly_lists).id
    # assert_response :success
    # rss_common_assertions
  end    
  
  def test_lists_smart_rss
    # get :lists_smart_rss, :smart_group_id => smart_groups(:ian_lists_tagged_with_orange).url_id
    # assert_response :success
    # rss_common_assertions
  end    
  
  def test_lists_notifications_rss
    # get :lists_notifications_rss
    # assert_response :success
    # rss_common_assertions
  end
  
  def assert_feedvalidator(rss, todo=nil)
    return unless $validator_installed

    begin
      file = Tempfile.new('connector-feed-test')
      filename = file.path
      file.write(rss)
      file.close

      messages = ''

      IO.popen("#{FV} file://#{filename}") do |pipe|
        messages = pipe.read
      end

      okay, messages = parse_validator_messages(messages)

      assert okay, messages 
      #print messages unless messages == ""
      #assert true
    end
  end

  def parse_validator_messages(message)
    messages=message.split(/\n/).reject do |m|
      m =~ /Feeds should not be served with the "text\/plain" media type/ ||
      m =~ /Self reference doesn't match document location/
    end

    if(messages.size > 1)
      [false, messages.join("\n")]
    else
      [true, ""]
    end
  end
  
end
