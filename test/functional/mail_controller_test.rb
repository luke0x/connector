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
require 'mail_controller'
require 'flexmock'

# Re-raise errors caught by the controller.
class MailController; def rescue_action(e) raise e end; end
class MailController; def sync_mailboxes() @mailboxes = User.find_by_username('ian').mailboxes; @mailbox_list = @mailboxes end; end

class MailControllerTest < Test::Unit::TestCase
  include FlexMock::TestCase
  fixtures all_fixtures
  
  def setup
    @controller = MailController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new

    @request.host = domains(:joyent).web_domain
    
    flexstub(Mailbox).should_receive(:list).with(users(:ian)).returns([])
  end

  def test_quick_contact
    login_person(:ian)    
    assert_nil organizations(:joyent).find_contact_with_email('joe@joemama.com')
    
    get :quick_contact, {:name => nil, :email => 'joe@joemama.com'} 
    assert_response :success
            
    person = organizations(:joyent).find_contact_with_email('joe@joemama.com')
    assert person
    assert_equal person.first_name, 'New'
    assert_equal person.last_name, 'Contact'
    
    assert_nil organizations(:joyent).find_contact_with_email('joe2@joemama.com')
    
    get :quick_contact, {:name => "Joe Mama", :email => 'joe2@joemama.com'} 
    assert_response :success
    
    person = organizations(:joyent).find_contact_with_email('joe2@joemama.com')
    assert person
    assert_equal person.first_name, 'Joe'
    assert_equal person.last_name, 'Mama'
  end
    
  def test_index_redirects_to_inbox_url
    login_person(:ian)
    get :index
    
    assert_response :redirect
    assert_redirected_to mail_special_list_url(:id => 'inbox')
  end

  def test_notifications
    login_person(:ian)
    get :notifications
    
    assert_response :success
    assert assigns(:notifications)
    assert_equal 'Notifications', assigns(:group_name)
    assert_template 'list'
    assert_toolbar([:all_notifications, :compose])
  end
  
  def test_notifications_ajax
    login_person(:ian)
    xhr :get, :notifications
               
    assert_response :success
    assert assigns(:notifications)
    assert_equal 'Notifications', assigns(:group_name)
    assert_template 'reports/_notifications'
  end

  def test_special_show
    mailbox = mailboxes(:ian_inbox)
    message = messages(:first)
    message.update_attribute(:active, true)


    body_mock = flexmock('messagebody')
    body_mock.should_receive(:body).returns('')
    body_mock.should_receive(:cc).returns([])
    
    flexstub(JoyentMaildir::MessageSync).should_receive(:sync_for).with(mailbox)
    flexstub(JoyentMaildir::Base).should_receive(:connection).returns {
      flexmock('connection') { |m| 
        m.should_receive(:message_seen).with_any_args
        m.should_receive(:mailbox_sync).with_any_args
        m.should_receive(:message_maildir_message).with_any_args.returns(body_mock)
      }
    }
    
    login_person(:ian)
    get :special_show, :mailbox => 'inbox', :id => message.id
    
    assert_response :success
    assert assigns(:message)
    assert_template 'mail/show'
  end
  
  def test_inbox
		flexstub(JoyentMaildir::Base).should_receive(:connection).once.returns {
		  flexmock('mailbox') {|m| m.should_receive(:mailbox_sync).with(mailboxes(:ian_inbox).id).once}
		}

    login_person(:ian)
    get :special_list, :id => 'inbox'

    assert_response :success
    assert_equal mailboxes(:ian_inbox).id, assigns(:mailbox).id
    assert_equal 'Inbox', assigns(:group_name)
    assert_template 'mail/list'
  end

  def test_sent
		flexstub(JoyentMaildir::Base).should_receive(:connection).once.returns {
		  flexmock('mailbox') {|m| m.should_receive(:mailbox_sync).with(mailboxes(:ian_sent).id).once}
		}

    login_person(:ian)
    get :special_list, :id => 'sent'
    
    assert_response :success
    assert_equal mailboxes(:ian_sent).id, assigns(:mailbox).id
    assert_equal 'Sent', assigns(:group_name)
    assert_template 'mail/list'
  end
  
  def test_drafts
		flexstub(JoyentMaildir::Base).should_receive(:connection).once.returns {
		  flexmock('mailbox') {|m| m.should_receive(:mailbox_sync).with(mailboxes(:ian_drafts).id).once}
		}
    
    login_person(:ian)
    get :special_list, :id => 'drafts'
    
    assert_response :success
    assert_equal mailboxes(:ian_drafts).id, assigns(:mailbox).id
    assert_equal 'Drafts', assigns(:group_name)
    assert_template 'mail/list'
  end
  
  def test_trash
		flexstub(JoyentMaildir::Base).should_receive(:connection).once.returns {
		  flexmock('mailbox') {|m| m.should_receive(:mailbox_sync).with(mailboxes(:ian_trash).id).once}
		}

    login_person(:ian)
    get :special_list, :id => 'trash'
    
    assert_response :success
    assert_equal mailboxes(:ian_trash).id, assigns(:mailbox).id
    assert_equal 'Trash', assigns(:group_name)
    assert_template 'mail/list'
  end
  
  def test_invalid_special_mailbox
    login_person(:ian)
    get :special_list, :id => 'invalid'
    
    assert_redirected_to mail_home_url
  end
  
  def test_mailbox
		flexstub(JoyentMaildir::Base).should_receive(:connection).once.returns {
		  flexmock('mailbox') {|m| m.should_receive(:mailbox_sync).with(mailboxes(:ian_inbox_concerts).id).once}
		}

    login_person(:ian)
    get :list, :id => mailboxes(:ian_inbox_concerts).id
    
    assert_response :success
    assert_equal mailboxes(:ian_inbox_concerts).id, assigns(:mailbox).id
    assert_equal mailboxes(:ian_inbox_concerts).name, assigns(:group_name)
    assert_template 'mail/list'
  end
  
  def test_mailbox_ajax
		flexstub(JoyentMaildir::Base).should_receive(:connection).once.returns {
		  flexmock('mailbox') {|m| m.should_receive(:mailbox_sync).with(mailboxes(:ian_inbox_concerts).id).once}
		}

    login_person(:ian)
    xhr :get, :list, :id => mailboxes(:ian_inbox_concerts).id
    
    assert_equal mailboxes(:ian_inbox_concerts).id, assigns(:mailbox).id
    assert_equal mailboxes(:ian_inbox_concerts).name, assigns(:group_name)
    assert_template '_messages'
    assert_response :success
  end

  
  def test_smart_group_attributes
    # JoyentMaildir::Base.connection.mailbox_sync self.id
    flexstub(JoyentMaildir::Base).should_receive(:connection).once.returns {
      flexmock('mailbox') {|m| m.should_receive(:mailbox_sync).with(mailboxes(:ian_inbox_concerts).id).once}
    }

    login_person(:ian)
    get :list, :id=> mailboxes(:ian_inbox_concerts).id
    assert_response :success
    assert_smart_group_attributes_assigned smart_group_descriptions(:messages)
  end
  
  def test_smart_list_ajax
    login_person(:ian)
    xhr :get, :smart_list, {:smart_group_id => smart_groups(:ian_foo_mail).url_id}
    assert_response :success    
  end

  def test_show
    mailbox = mailboxes(:ian_inbox)
    message = messages(:first)
    message.update_attribute(:active, true)


    body_mock = flexmock('messagebody')
    body_mock.should_receive(:body).returns('')
    body_mock.should_receive(:cc).returns([])
    
    flexstub(JoyentMaildir::MessageSync).should_receive(:sync_for).with(mailbox)
    flexstub(JoyentMaildir::Base).should_receive(:connection).returns {
      flexmock('connection') { |m| 
        m.should_receive(:message_seen).with_any_args
        m.should_receive(:mailbox_sync).with_any_args
        m.should_receive(:message_maildir_message).with_any_args.returns(body_mock)
      }
    }

    login_person(:ian)
    get :show, :mailbox => mailboxes(:ian_inbox).id, :id => messages(:first).id
    
    assert assigns(:message)
    assert assigns(:mailbox)
    assert_response :success
  end
  
  def test_smart_show
    message = messages(:first)
    message.update_attribute(:active, true)

    body_mock = flexmock('messagebody')
    body_mock.should_receive(:body).returns('')
    body_mock.should_receive(:cc).returns([])
    
    flexstub(JoyentMaildir::Base).should_receive(:connection).returns {
      flexmock('connection') { |m| 
        m.should_receive(:message_seen).with_any_args
        m.should_receive(:mailbox_sync).with_any_args
        m.should_receive(:message_maildir_message).with_any_args.returns(body_mock)
      }
    }

    login_person(:ian)
    get :smart_show, :smart_group_id => "s5", :id => 1
    
    assert assigns(:smart_group)
    assert assigns(:group_name)
    assert assigns(:message)
    assert assigns(:messages)
    assert assigns(:paginator)
  end

  def test_peek
    mailbox = mailboxes(:ian_inbox)
    message = messages(:first)
    
    flexstub(Message).should_receive(:find).with(1).and_return {message}
    flexstub(Mailbox).should_receive(:find).with(1).and_return {
      mailbox
    }
    
    flexstub(Mailbox).should_receive(:find).with(mailbox.id.to_s, :include => [:owner], :scope => :read).once.and_return {
      flexstub(mailbox).should_receive(:sync)
      flexstub(mailbox).should_receive(:messages).and_return {
        flexmock('messages') { |m|
          m.should_receive(:find).with(:all, {:order=>"messages.date DESC", :conditions=>["messages.active=?", true], :scope=>:read}).and_return([])
          m.should_receive(:count).and_return(1)
          m.should_receive(:find).with(message.id.to_s, :conditions => ["messages.active = ?", true], :scope => :read).and_return {
            flexstub(message).should_receive(:seen!)
            flexstub(message).should_receive(:body).returns('')
            flexstub(message).should_receive(:cc).returns([])
            flexstub(message).should_receive(:multipart?).returns(false)
            flexstub(message).should_receive(:display_structure).returns([['utf8', '']])
            message
          }
        }
      }
      mailbox
    }
    
    login_person(:ian)
    xhr :get, :show, :mailbox => mailbox.id, :id => message.id

    assert_response :success
    assert assigns(:message)
    assert_template '_peek'
    assert_no_layout
  end

  def test_delete
    flexstub(User).should_receive(:current).returns {
      user = users(:ian)
      flexstub(user).should_receive(:messages).returns {
        flexmock('messages') {|m|
          m.should_receive(:find_all_by_id_and_active).with([messages(:first).id.to_s], true).once.returns {
            [ flexmock('message') do |m2| 
                m2.should_receive(:exist?).returns(true)
                m2.should_receive(:mailbox_id).once.returns(messages(:first).mailbox_id)
                m2.should_receive(:owner).returns(users(:ian))
                m2.should_receive(:move_to).with(users(:ian).trash).once
              end]
          }
        }
      }
      user
    }
    
    @request.env["HTTP_REFERER"] = '/mail/mailbox/inbox'
    login_person(:ian)
    get :delete, :id => messages(:first).id
    assert_response :redirect
  end
  
  def test_delete_multiple
    ids = [messages(:first).id.to_s, messages(:another).id.to_s]

    flexstub(User).should_receive(:current).returns {
      user = users(:ian)
      flexstub(user).should_receive(:messages).returns {
        flexmock('messages') {|m|
          m.should_receive(:find_all_by_id_and_active).with(ids, true).once.returns {
            [ flexmock('message') do |m2| 
              m2.should_receive(:exist?).returns(true)
              m2.should_receive(:mailbox_id).once.returns(messages(:first).mailbox_id)
                m2.should_receive(:owner).returns(users(:ian))
                m2.should_receive(:move_to).with(users(:ian).trash).once
              end,
              flexmock('message') do |m2| 
                m2.should_receive(:exist?).returns(true)
                m2.should_receive(:owner).returns(users(:ian))
                m2.should_receive(:move_to).with(users(:ian).trash).once
              end]
          }
        }
      }
      user
    }

    @request.env["HTTP_REFERER"] = '/mail/mailbox/inbox'
    login_person(:ian)
    get :delete, :ids => "#{messages(:first).id},#{messages(:another).id}"
    assert_response :redirect
  end
  
  def test_move
    ids = [messages(:first).id.to_s]
    flexstub(Message).should_receive(:find).with(ids, :conditions => ["messages.active = ?", true], :scope => :move).once.and_return {
      [flexmock('msg') {|m| m.should_receive(:move_to).with(mailboxes(:ian_inbox_concerts)).once}]
    }

    @request.env["HTTP_REFERER"] = '/mail/mailbox/inbox'
    login_person(:ian)
    post :move, :new_group_id => mailboxes(:ian_inbox_concerts).id, :id => messages(:first).id
    assert_response :redirect
  end
  
  def test_move_multiple
    ids = [messages(:first).id.to_s, messages(:another).id.to_s]
    flexstub(Message).should_receive(:find).with(ids, :conditions => ["messages.active = ?", true], :scope => :move).once.and_return {
      [ flexmock('msg1') {|m| m.should_receive(:move_to).with(mailboxes(:ian_inbox_concerts)).once},
        flexmock('msg2') {|m| m.should_receive(:move_to).with(mailboxes(:ian_inbox_concerts)).once} ]
    }
    @request.env["HTTP_REFERER"] = '/mail/mailbox/inbox'
    login_person(:ian)
    post :move, :new_group_id => mailboxes(:ian_inbox_concerts).id, :ids => "#{messages(:first).id},#{messages(:another).id}"
    assert_response :redirect
  end

  def test_copy
    ids = [messages(:first).id.to_s]
    flexstub(Message).should_receive(:find).with(ids, {:scope => :copy, :conditions => ["messages.active = ?", true]}).once.and_return {
      [ flexmock('msg1') {|m| m.should_receive(:copy_to).with(mailboxes(:ian_inbox_concerts)).once},
        flexmock('msg2') {|m| m.should_receive(:copy_to).with(mailboxes(:ian_inbox_concerts)).once} ]
    }
    @request.env["HTTP_REFERER"] = '/mail/mailbox/inbox'
    login_person(:ian)
    post :copy, :new_group_id => mailboxes(:ian_inbox_concerts).id, :id => messages(:first).id
    assert_response :redirect
  end

  def test_copy_multiple
    ids = [messages(:first).id.to_s, messages(:another).id.to_s]
    flexstub(Message).should_receive(:find).with(ids, {:scope => :copy, :conditions => ["messages.active = ?", true]}).once.and_return {
      [ flexmock('msg1') {|m| m.should_receive(:copy_to).with(mailboxes(:ian_inbox_concerts)).once},
        flexmock('msg2') {|m| m.should_receive(:copy_to).with(mailboxes(:ian_inbox_concerts)).once} ]
    }
    @request.env["HTTP_REFERER"] = '/mail/mailbox/inbox'
    login_person(:ian)
    post :copy, :new_group_id => mailboxes(:ian_inbox_concerts).id, :ids => "#{messages(:first).id},#{messages(:another).id}"
    assert_response :redirect
  end
  
  def test_redirect_to_mailbox_from_list_for_normal_mailbox
    ids = [messages(:first).id.to_s, messages(:another).id.to_s]
    flexstub(User).should_receive(:current).returns {
      user = users(:ian)
      flexstub(user).should_receive(:messages).returns {
        flexmock('messages') {|m|
          m.should_receive(:find_all_by_id_and_active).with(ids, true).once.returns {
            [ flexmock('message') do |m2| 
                m2.should_receive(:exist?).returns(true)
                m2.should_receive(:mailbox_id).once.returns(messages(:first).mailbox_id)
                m2.should_receive(:owner).returns(users(:ian))
                m2.should_receive(:move_to).with(users(:ian).trash).once
              end,
              flexmock('message') do |m2| 
                m2.should_receive(:exist?).returns(true)
                m2.should_receive(:owner).returns(users(:ian))
                m2.should_receive(:move_to).with(users(:ian).trash).once
              end]
          }
        }
      }
      user
    }

    login_person(:ian)
    @request.env["HTTP_REFERER"] = '/mail/mailbox/' + messages(:first).mailbox_id.to_s
    get :delete, :ids => "#{messages(:first).id},#{messages(:another).id}", :mailbox => mailboxes(:ian_inbox_concerts).id
    
    assert_response :redirect
    assert_redirected_to mail_mailbox_url(:id => messages(:first).mailbox_id.to_s)
  end
  
  def test_redirect_to_mailbox_from_list_for_special_mailbox
    ids = [messages(:first).id.to_s, messages(:another).id.to_s]
    flexstub(Message).should_receive(:find).with(ids, :conditions => ["messages.active = ?", true], :scope => :delete).returns {
      [ flexmock('message') do |m2| 
        m2.should_receive(:exist?).returns(true)
        m2.should_receive(:mailbox_id).once.returns(messages(:first).mailbox_id)
          m2.should_receive(:owner).returns(users(:ian))
          m2.should_receive(:move_to).with(users(:ian).trash).once
        end,
        flexmock('message') do |m2| 
          m2.should_receive(:exist?).returns(true)
          m2.should_receive(:owner).returns(users(:ian))
          m2.should_receive(:move_to).with(users(:ian).trash).once
        end]
    }

    login_person(:ian)
    @request.env["HTTP_REFERER"] = '/mail/mailbox/inbox'
    post :delete, :ids => "#{messages(:first).id},#{messages(:another).id}", :mailbox => 'inbox'
    
    assert_response :redirect
    assert_redirected_to mail_mailbox_url(:id => mailboxes(:ian_inbox).id)
  end
    
  def test_compose
    login_person(:ian)
    get :compose
    
    assert_response :success
  end

  def test_smart_list
    login_person(:ian)
    get :smart_list, {:smart_group_id => smart_groups(:ian_foo_mail).url_id}
    assert_response :success
  end
  
  def test_create_with_parent_set
    create_mock = flexmock('joyentmbox')
		create_mock.should_receive(:mailbox_create_child).with(mailboxes(:ian_inbox).id, 'INBOX.Concerts.who').once.returns({:uidvalidity => 69, :uidnext => 42})
		
		flexstub(JoyentMaildir::Base).should_receive(:connection).once.returns(create_mock)

    login_person(:ian)
    post :create_mailbox, :parent_id => mailboxes(:ian_inbox_concerts).id, :group_name => 'who'
    
    assert_response :redirect
    assert(mb = Mailbox.find_by_full_name('INBOX.Concerts.who'))
  end
  
  def test_create_with_no_parent_set
    create_mock = flexmock('joyentmbox')
		create_mock.should_receive(:mailbox_create_child).with(mailboxes(:ian_inbox).id, 'INBOX.blingbling').once.returns({:uidvalidity => 69, :uidnext => 42})
		
		flexstub(JoyentMaildir::Base).should_receive(:connection).once.returns(create_mock)
		
    login_person(:ian)
    post :create_mailbox, :parent_id => '', :group_name => 'blingbling'
    
    assert_response :redirect
    assert(mb = Mailbox.find_by_full_name('INBOX.blingbling'))
  end

  def test_empty_trash
    flexstub(Mailbox).should_receive(:empty_trash).with(users(:ian)).once
    login_person(:ian)
    
    post :empty_trash

    assert_response :redirect
    assert_redirected_to mail_special_list_url(:id => 'trash')
  end
  
  def test_mailbox_rename
		rename_mock = flexmock('joyentmbox')
		rename_mock.should_receive(:mailbox_rename).with(mailboxes(:ian_inbox_concerts_2006).id, 'INBOX.Concerts.waffles').once.returns({:uidvalidity => 69, :uidnext => 42})
		
		flexstub(JoyentMaildir::Base).should_receive(:connection).once.returns(rename_mock)

    @request.env["HTTP_REFERER"] = '/mail/mailbox/inbox'
    login_person(:ian)
    post :rename_group, :id => mailboxes(:ian_inbox_concerts_2006).id, :name => 'waffles'
    
    assert_response :redirect
    assert_equal 'INBOX.Concerts.waffles', mailboxes(:ian_inbox_concerts_2006).reload.full_name
  end
  
  def test_get_compose
    login_person(:ian)
    get :compose
    assert_response :success
  end
  
  def test_addresses_for_lookup
    login_person(:ian)
    get :addresses_for_lookup
    assert_response :success
    assert assigns(:addresses)
  end

  # def test_inbox_unread_count
  #   login_person(:ian)
  #   get :inbox_unread_count
  # 
  #   assert_response :success
  #   assert_equal 5, @response.body.to_i
  # end                  
  
  def test_unread_messages
		flexstub(JoyentMaildir::Base).should_receive(:connection).once.returns {
		  flexmock('mailbox') {|m| m.should_receive(:mailbox_sync).with(mailboxes(:ian_inbox).id).once}
		}

    login_person(:ian)
    get :unread_messages
    assert assigns(:messages)                    
    assert_response :success
  end                     
  
  def test_unread_messages_ajax
		flexstub(JoyentMaildir::Base).should_receive(:connection).once.returns {
		  flexmock('mailbox') {|m| m.should_receive(:mailbox_sync).with(mailboxes(:ian_inbox).id).once}
		}

    login_person(:ian)
    xhr :get, :unread_messages
    assert assigns(:messages)                    
    assert_response :success    
  end                        
  
  def test_regression_for_2750
		flexstub(JoyentMaildir::Base).should_receive(:connection).once.returns {
		  flexmock('mailbox') {|m| m.should_receive(:mailbox_sync).with(mailboxes(:ian_inbox).id).once}
		}

    login_person(:ian)
    get :special_list, :id => 'inbox'

    assert_response :success
    assert assigns(:mailbox)
    assert_equal mailboxes(:ian_inbox).id, assigns(:mailbox).id
  end
    
  # If a to parameter is passed, e.g. from a contact page by clicking the email
  # address, set the value of to input to the parameter passed in.
  def test_regression_for_2888
    login_person(:ian)
    get :compose, :to => 'scott@joyent.com'
    
    assert_response :success
    # FIX use a regex because of malformed html
#    assert_tag :tag => 'input', :attributes => {:id => 'message_to_complete', :value => 'scott@joyent.com'}
  end
  
  def test_delete_group
    id = mailboxes(:ian_inbox_concerts_2006).id.to_s
    flexstub(Mailbox).should_receive(:find).with(id, :scope => :delete).once.returns {
      flexmock('msg') {|m| m.should_receive(:delete!).once}
    }
    
    login_person(:ian)
    post :delete_group, :id => mailboxes(:ian_inbox_concerts_2006).id
    
    assert_response :redirect
    assert_redirected_to mail_special_list_url(:id => 'inbox')
  end
  
  def test_flag
    id = messages(:first).id.to_s
    msg = Message.find(id)
    flexstub(Message).should_receive(:find).with(id, {:conditions => ["messages.active = ?", true], :scope => :edit}).once.returns {
      flexstub(msg).should_receive(:flag!).once
      msg
    }
    
    login_person(:ian)
    post :flag, :id => messages(:first).id
    assert_response :success
  end
  
  def test_unflag
    id = messages(:first).id.to_s
    msg = Message.find(id)
    flexstub(Message).should_receive(:find).with(id, {:conditions => ["messages.active = ?", true], :scope => :edit}).once.returns {
      flexstub(msg).should_receive(:unflag!).once
      msg
    }
    
    login_person(:ian)
    post :unflag, :id => messages(:first).id
    assert_response :success    
  end
  
  def test_reparent_group
		reparent_mock = flexmock('joyentmbox')
		reparent_mock.should_receive(:mailbox_rename).with(mailboxes(:ian_inbox_concerts_2006).id, 'INBOX.2006').once.returns({:uidvalidity => 69, :uidnext => 42})

    jm_base = flexstub(JoyentMaildir::Base)
    jm_base.should_receive(:connection).once.returns(reparent_mock)

    @request.env["HTTP_REFERER"] = '/mail/mailbox/inbox'

    login_person(:ian)
    post :reparent_group, :group_id => mailboxes(:ian_inbox_concerts_2006).id, :new_parent_id => mailboxes(:ian_inbox).id
    assert_response :redirect
  end
  
  # regression test for case #21
  def test_time_ago_and_localization
  	flexstub(JoyentMaildir::Base).should_receive(:connection).once.returns {
		  flexmock('mailbox') {|m| m.should_receive(:mailbox_sync).with(mailboxes(:ian_inbox).id).once}
		}

    login_person(:ian)
    get :list, :id => mailboxes(:ian_inbox).id
    assert_nil @response.body =~ /ago ago/
  end
  
end
