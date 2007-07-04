=begin #(fold)
Copyright 2004-2007 Joyent Inc.

Redistribution and/or modification of this code is governed
by either the GPLv2 or Joyent Commercial Software licenses.

Report issues and contribute at http://dev.joyent.com/

$Id$
=end #(end)

require File.dirname(__FILE__) + '/../test_helper'

context "A maildir message" do
  fixtures all_fixtures

  specify "can be deleted" do
    jmdmessage = JoyentMaildir::Message.new(messages(:first))
    src        = JoyentMaildir::MaildirPath.build('joyent.joyent.com', 'ian', messages(:first).mailbox.full_name)
    filename   = jmdmessage.send(:get_filename)
    src_path   = File.join(src, 'cur', filename)

    assert MockFS.file.exist?(src_path)
    jmdmessage.delete
    assert !MockFS.file.exist?(src_path)
  end
  
  specify "can be copied to another mailbox" do
    jmdmessage = JoyentMaildir::Message.new(messages(:first))
    src        = JoyentMaildir::MaildirPath.build('joyent.joyent.com', 'ian', messages(:first).mailbox.full_name)
    dst        = JoyentMaildir::MaildirPath.build('joyent.joyent.com', 'ian', mailboxes(:ian_inbox_concerts).full_name)
    filename   = jmdmessage.send(:get_filename)
    src_path   = File.join(src, 'cur', filename)

    assert MockFS.file.exist?(src_path)

    new_base = jmdmessage.copy_to mailboxes(:ian_inbox_concerts)
    dst_path = File.join(dst, 'cur', new_base)
    
    assert MockFS.file.exist?(src_path)
    assert MockFS.file.exist?(dst_path)
  end
  
  specify "can be moved to another mailbox" do
    jmdmessage = JoyentMaildir::Message.new(messages(:first))
    src        = JoyentMaildir::MaildirPath.build('joyent.joyent.com', 'ian', messages(:first).mailbox.full_name)
    dst        = JoyentMaildir::MaildirPath.build('joyent.joyent.com', 'ian', mailboxes(:ian_inbox_concerts).full_name)
    filename   = jmdmessage.send(:get_filename)
    src_path   = File.join(src, 'cur', filename)

    assert MockFS.file.exist?(src_path)

    new_base = jmdmessage.move_to mailboxes(:ian_inbox_concerts)
    dst_path = File.join(dst, 'cur', new_base)
    
    assert !MockFS.file.exist?(src_path)
    assert MockFS.file.exist?(dst_path)
  end
  
  specify "can be marked seen" do
    jmdmessage = JoyentMaildir::Message.new(messages(:first))
    jmdmessage.seen
    
    assert JoyentMaildir::Message.new(messages(:first)).flags.include?('S')    
  end
 
  specify "can be marked flagged" do
    jmdmessage = JoyentMaildir::Message.new(messages(:first))
    jmdmessage.flag
    
    assert JoyentMaildir::Message.new(messages(:first)).flags.include?('F')
  end
end

context "a flagged message" do
  fixtures all_fixtures
  
  specify "can be unflagged" do
    jmdmessage = JoyentMaildir::Message.new(messages(:first))
    jmdmessage.unflag
    
    assert !JoyentMaildir::Message.new(messages(:first)).flags.include?('F')
  end
end
