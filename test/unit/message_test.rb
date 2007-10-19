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
require 'ostruct'
require 'flexmock'

class MessageTest < Test::Unit::TestCase
  include CRUDTest
  include FlexMock::TestCase
  fixtures all_fixtures
  
  crud_data 'organization_id' => 1,
            'user_id'         => 1,
            'mailbox_id'      => 1,
            'size_in_bytes'   => 1024,
            'filename'        => 'foobar',
            'internaldate'    => Time.now
            
  crud_required 'organization_id', 'user_id', 'mailbox_id', 'size_in_bytes', 'filename', 'internaldate'

  def test_move_to
    flexstub(JoyentMaildir::Base).should_receive(:connection).once.returns {
      flexmock('msg') {|m| m.should_receive(:message_move_to).with(messages(:first).id, mailboxes(:ian_inbox_concerts).id)}
    }
    
    
    messages(:first).move_to mailboxes(:ian_inbox_concerts)
    assert_nil Message.find_by_id_and_active(messages(:first).id, true)
  end
  
  def test_copy_to_creates_proxy_and_clones_assets
    copy_mock = flexmock('message')
    copy_mock.should_receive(:message_copy_to).with(messages(:first).id, mailboxes(:ian_inbox_concerts).id).once
    
    flexstub(JoyentMaildir::Base).should_receive(:connection).returns(copy_mock)
    
    messages(:first).copy_to mailboxes(:ian_inbox_concerts)
  end
  
  def test_seen
    flexstub(JoyentMaildir::Base).should_receive(:connection).once.returns {
      flexmock('msg') { |m| m.should_receive(:message_seen).with(messages(:first).id) }
    }
    
    messages(:first).seen!
    assert messages(:first).reload.seen?
  end
  
  def test_flag
    flexstub(JoyentMaildir::Base).should_receive(:connection).once.returns {
      flexmock('msg') { |m| m.should_receive(:message_flag).with(messages(:first).id) }
    }

    Message.find(messages(:first).id).update_attribute :flagged, false
    
    messages(:first).flag!
    assert Message.find(messages(:first).id).flagged?
  end

  def test_unflag
    flexstub(JoyentMaildir::Base).should_receive(:connection).once.returns {
      flexmock('msg') { |m| m.should_receive(:message_unflag).with(messages(:first).id) }
    }

    messages(:first).unflag!
    assert !messages(:first).flagged?
  end
  
  def test_build_reply_stub
    body_mock = flexmock('messagebody')
    
    message_mock = flexmock('message')
    message_mock.should_receive(:message_body).with(1, true).once.returns('')
    
    flexstub(JoyentMaildir::Base).should_receive(:connection).once.returns(message_mock)
    
    msg = messages(:first).build_reply_stub
    assert_equal ["Foo Bar <foo@bar.com>"], msg.to
    assert_equal "Re: a subject", msg.subject
    assert msg.body =~ /^On .*, Foo Bar <foo@bar.com> wrote:/
  end
  
  def test_build_forward
    body_mock = flexmock('messagebody')
    body_mock.should_receive(:multipart).once.returns(false)
    
    message_mock = flexmock('message')
    message_mock.should_receive(:message_body).with(1, false).once.returns('')
    message_mock.should_receive(:message_maildir_message).with(messages(:first).id).once.returns(body_mock)
    
    flexstub(JoyentMaildir::Base).should_receive(:connection).twice.returns(message_mock)
    
    msg = messages(:first).build_forward_stub
    assert_equal [], msg.to
    assert_equal "Fwd: a subject", msg.subject
    assert msg.body =~ /^On .*, Foo Bar <foo@bar.com> wrote:/
  end
  
  # New stuff
  def test_delete
    flexstub(JoyentMaildir::Base).should_receive(:connection).once.returns {
      flexmock('msg') { |m| m.should_receive(:message_delete).with(messages(:first).id) }
    }
    
    id = messages(:first).id
    
    messages(:first).delete!
    
    assert_nil Message.find_by_id(id)
  end
  
  # Regression test to case 387
  # BCC field not showing on edit draft
  # This ensures bcc field is parsed from raw message
  def test_message_returns_bcc
    mock_maildir = JoyentMaildir::MockMaildirWorker.new
    
    flexstub(JoyentMaildir::Base).should_receive(:connection).twice.returns {
      flexmock('message') do |m| 
        m.should_receive(:message_maildir_message).with(messages(:first).id).returns(mock_maildir.message_maildir_message(messages(:first).id))
        m.should_receive(:message_body).with(1, false).returns('')
      end
    }
    
    msg = messages(:first).build_draft_stub
    assert_equal "you@joyent.com", msg.bcc.first.address
  end
  
#   def test_rfc2047_headers
#     m = messages(:first)
#     addr = OpenStruct.new
#     addr.name    = '"=?ISO-8859-2?Q?Filip_Hajn=FD?='
#     addr.mailbox = 'filip'
#     addr.host    = 'textdrive.com'
#   
#     m.from
#   
#     imap_msg = m.instance_variable_get("@_imap_message")
#     imap_msg.from = [addr]
#     imap_msg.to   = [addr]
#     imap_msg.subject="=?Big5?B?uXGo68K4?= EMBROIDERED-CUSTOM , OVERRUNS =?Big5?B?LVBBVENIRVMuLcCys7m1pTIwMDYvNS8xNyCkVaTI?= 10:12:39"
#   
#     assert_equal "\351\233\273\345\210\272\347\271\241 EMBROIDERED-CUSTOM , OVERRUNS -PATCHES.-\345\276\275\347\253\240\347\255\2112006/5/17 \344\270\213\345\215\210 10:12:39", m.subject
#     assert_equal "Filip Hajn\303\275 <filip@textdrive.com>", m.from
#   
#   end
end
