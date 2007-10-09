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
require 'flexmock'

class MailboxTest < Test::Unit::TestCase
  fixtures all_fixtures
  include CRUDTest
  include FlexMock::TestCase
  
  crud_data 'full_name'       => 'INBOX.blah',
            'uid_validity'    => 135791113,
            'uid_next'        => 8,
            'parent_id'       => 1,
            'user_id'         => 1,
            'organization_id' => 1
  
  crud_required 'full_name', 'uid_validity', 'uid_next', 'user_id', 'organization_id'
  
  def test_uid_validity_numericality
    @test_data['uid_validity'] = 'foobar'
    assert_no_create
  end
  
  def test_uid_next_numericality
    @test_data['uid_next'] = 'foobar'
    assert_no_create
  end
  
  def test_name
    assert_equal '2006', mailboxes(:ian_inbox_concerts_2006).name
  end
  
  def test_relative_name
    assert_equal 'INBOX',         mailboxes(:ian_inbox).relative_name
    assert_equal 'Concerts',      mailboxes(:ian_inbox_concerts).relative_name
    assert_equal 'Concerts.2006', mailboxes(:ian_inbox_concerts_2006).relative_name
  end
  
  def test_parent_name
    assert_equal 'INBOX.Concerts', mailboxes(:ian_inbox_concerts_2006).parent_name
    assert_equal 'INBOX', mailboxes(:ian_inbox_concerts).parent_name
    assert_nil mailboxes(:ian_inbox).parent_name
  end
   
  def test_level
    assert_equal 0, mailboxes(:ian_inbox).level
    assert_equal 1, mailboxes(:ian_inbox_concerts).level
    assert_equal 2, mailboxes(:ian_inbox_concerts_2006).level
  end
  
  # Added since maildir integration
  def test_count
		count_mock = flexmock('joyentmbox')
		count_mock.should_receive(:mailbox_count).once.returns(OpenStruct.new(:messages => 5, :unseen => 4))

    jm_base = flexstub(JoyentMaildir::Base)
    jm_base.should_receive(:connection).once.returns(count_mock)
        
    count = mailboxes(:ian_inbox).count
    assert_equal 5, count.messages
    assert_equal 4, count.unseen
  end
  
  def test_create_child
    User.current = users(:ian)
		create_mock = flexmock('joyentmbox')
		create_mock.should_receive(:mailbox_create_child).with(mailboxes(:ian_inbox).id, 'INBOX.new_mailbox').once.returns({:uidvalidity => 69, :uidnext => 42})
		
		flexstub(JoyentMaildir::Base).should_receive(:connection).once.returns(create_mock)
    
    child = mailboxes(:ian_inbox).create_child('new_mailbox')
    assert child.valid?
    assert_equal "INBOX.new_mailbox", child.full_name
    assert child.id
    assert_equal mailboxes(:ian_inbox), child.parent
  end
  
  def test_delete		
		delete_mock = flexmock('joyentmbox')
		delete_mock.should_receive(:mailbox_delete).with(mailboxes(:ian_delete_me).id).once
		
		flexstub(JoyentMaildir::Base).should_receive(:connection).once.returns(delete_mock)
		    
    mailboxes(:ian_delete_me).delete!
    
    assert_nil Mailbox.find_by_id(mailboxes(:ian_delete_me).id)
  end
  
  def test_delete_cannot_delete_inbox
    flexstub(JoyentMaildir::Mailbox).should_receive(:new).never
    
    mailboxes(:ian_inbox).delete!
    
    assert Mailbox.find_by_id(mailboxes(:ian_inbox).id)
  end
  
  def test_delete_deletes_children_proxies
		delete_mock = flexmock('joyentmbox')
		delete_mock.should_receive(:mailbox_delete).with(mailboxes(:ian_inbox_concerts).id).once
		delete_mock.should_receive(:mailbox_delete).with(mailboxes(:ian_inbox_concerts_2006).id).once
		
		flexstub(JoyentMaildir::Base).should_receive(:connection).returns(delete_mock)
    
    cid = mailboxes(:ian_inbox_concerts_2006).id
    
    mailboxes(:ian_inbox_concerts).delete!
    
    assert_nil Mailbox.find_by_id(cid)
  end
  
  def test_rename
		rename_mock = flexmock('joyentmbox')
		rename_mock.should_receive(:mailbox_rename).with(mailboxes(:ian_delete_me).id, 'INBOX.pancakes').once.returns({:uidvalidity => 69, :uidnext => 42})
		
		flexstub(JoyentMaildir::Base).should_receive(:connection).once.returns(rename_mock)
    
    mailboxes(:ian_delete_me).rename! 'pancakes'
    
    assert_equal 'INBOX.pancakes', mailboxes(:ian_delete_me).reload.full_name
    assert_equal 69, mailboxes(:ian_delete_me).uid_validity
    assert_equal 42, mailboxes(:ian_delete_me).uid_next
  end
  
  # tests that koz should have written
  def test_cascade_permissions_uses_joyent_job
    fm = flexmock('joyentjob')
    fm.should_receive(:submit).once
    flexstub(JoyentJob::Job).should_receive(:new).with(Mailbox, mailboxes(:ian_inbox).id, :real_cascade_permissions).returns(fm).once
    
    mailboxes(:ian_inbox).cascade_permissions
  end
  
  def test_descendent_returns_false_if_passed_nil
    assert !mailboxes(:ian_inbox).descendent?(nil)
  end
  
  def test_descendent_returns_false_if_no_children
    assert !Mailbox.new.descendent?(mailboxes(:ian_delete_me))
  end
  
  def test_descendent_returns_true_for_direct_descendent
    assert mailboxes(:ian_inbox).descendent?(mailboxes(:ian_delete_me))
  end
  
  def test_descendent_returns_true_for_grandchild
    assert mailboxes(:ian_inbox).descendent?(mailboxes(:ian_inbox_concerts_2006))
  end
  
  def test_reparent_nil_if_trying_to_reparent_to_itself
    assert_nil mailboxes(:ian_inbox).reparent!(mailboxes(:ian_inbox))
  end
  
  def test_reparent_cannot_reparent_yourself_to_a_descendent
    assert_nil mailboxes(:ian_inbox).reparent!(mailboxes(:ian_inbox_concerts_2006))
  end
  
  def test_reparent		
		reparent_mock = flexmock('joyentmbox')
		reparent_mock.should_receive(:mailbox_rename).with(mailboxes(:ian_inbox_concerts_2006).id, 'INBOX.2006').once.returns({:uidvalidity => 69, :uidnext => 42})

    jm_base = flexstub(JoyentMaildir::Base)
    jm_base.should_receive(:connection).once.returns(reparent_mock)
		
    mailboxes(:ian_inbox_concerts_2006).reparent!(mailboxes(:ian_inbox))
    
    assert_equal 'INBOX.2006', mailboxes(:ian_inbox_concerts_2006).reload.full_name
    assert_equal mailboxes(:ian_inbox), mailboxes(:ian_inbox_concerts_2006).parent
  end
  
  def test_empty_trash
    User.current = users(:ian)
    
    trash_mock = flexmock('joyentmbox')
    trash_mock.should_receive(:mailbox_empty_trash).with(users(:ian).id).once

    flexstub(JoyentMaildir::Base).should_receive(:connection).once.returns(trash_mock)
    
    Mailbox.empty_trash(users(:ian))
    
    assert users(:ian).reload.trash.messages.empty?
  end
end
