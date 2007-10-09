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

context "A mailbox count operation" do  
  fixtures all_fixtures
  
  def setup
    @counts = JoyentMaildir::Mailbox.new(mailboxes(:ian_inbox)).count
  end
  
  specify "contains the number of messages not including deleted messages" do
    assert_equal 3, @counts.messages
  end
  
  specify "contains the number of unread messages" do
    assert_equal 2, @counts.unseen
  end
end

# context "Deleting a mailbox" do
#   include FlexMock::TestCase
#   fixtures all_fixtures
#   
#   specify "deletes a mailbox that exists" do
#     mail_root = ENV['JOYENT_MAILDIR'] || '/home/vmail'
#     target = "#{mail_root}/joyent.joyent.com/ian/Maildir/.delete_me"
#     flexstub(FileUtils).should_receive(:rm_rf).with(target).once
#     
#     JoyentMaildir::Mailbox.new(mailboxes(:ian_delete_me)).delete
#   end
# end
# 
# context "Renaming a mailbox" do  
#   include FlexMock::TestCase
#   fixtures all_fixtures
# 
#   def setup
#     @mailbox    = mailboxes(:ian_delete_me)
#     mail_root = ENV['JOYENT_MAILDIR'] || '/home/vmail'
#     @src = "#{mail_root}/joyent.joyent.com/ian/Maildir/.delete_me"
#     @dst = JoyentMaildir::MaildirPath.build('joyent.joyent.com', 'ian', 'INBOX.renamed')
#   end
#   
#   specify "renames the maildir and resets uidnext and uidvalidity" do
#     t = Time.now
#     flexstub(Time).should_receive(:now).returns(t)
#     
#     uiddb     = ["1 1159973875 3\n",
#                  "2 1159907087.M314678P19340V01980007I0007604D_1.unknown,S=20866\n"]
#     new_uiddb = "1 #{t.to_i} 2\n1 1159907087.M314678P19340V01980007I0007604D_1.unknown,S=20866\n"
#     
#     uiddb_mock = flexmock('uiddb')
#     uiddb_mock.should_receive(:readlines).returns(uiddb).once.ordered(:uiddb1)
#     uiddb_mock.should_receive(:close)
# 
#     nuiddb_mock = flexmock('nuiddb')
#     nuiddb_mock.should_receive(:write).with(new_uiddb).once.ordered(:uiddb2)
#     nuiddb_mock.should_receive(:close)
#     
#     subscribe = flexmock('subscribe')
#     subscribe.should_receive(:write).with("INBOX.renamed\n")
#     subscribe.should_receive(:close)
# #    flexstub(File).should_receive(:open).with("/home/vmail/joyent.joyent.com/ian/Maildir/.renamed/../courierimapsubscribed", 'a').returns(subscribe).once.ordered    
#     
#     # Verify that the maildir was moved
#     flexstub(FileUtils).should_receive(:mv).with(@src, @dst).once.ordered
#     # Provide the mock data
#     flexstub(File).should_receive(:open).with(File.join(@dst, 'courierimapuiddb')).returns(uiddb_mock).once.ordered
#     # Verify that the data was properly written
#     flexstub(File).should_receive(:open).with(File.join(@dst, 'courierimapuiddb'), 'w').returns(nuiddb_mock).once.ordered
#     
#     results = JoyentMaildir::Mailbox.new(@mailbox).rename('INBOX.renamed')
#     assert_equal t.to_i, results[:uidvalidity]
#     assert_equal 2, results[:uidnext]
#   end
# end
# 
# context "Creating a mailbox" do
#   include FlexMock::TestCase
#   fixtures all_fixtures
# 
#   def setup
#     Mailbox.destroy_all
#     @name  = JoyentMaildir::MaildirPath.build('joyent.joyent.com', 'ian', 'INBOX.new_mailbox')
#     @inbox = JoyentMaildir::MaildirPath.build('joyent.joyent.com', 'ian', 'INBOX')
#   end
#   
#   specify "creates the mailbox in the maildir and subscribes it" do
#     t = Time.now
#     flexstub(Time).should_receive(:now).returns(t)
#     
#     # Verify that the maildir was properly created
#     flexstub(FileUtils).should_receive(:mkdir).with(@name).once.ordered
#     flexstub(FileUtils).should_receive(:mkdir).with(File.join(@name, 'cur')).once.ordered
#     flexstub(FileUtils).should_receive(:mkdir).with(File.join(@name, 'new')).once.ordered
#     flexstub(FileUtils).should_receive(:mkdir).with(File.join(@name, 'tmp')).once.ordered
#     
#     # Verify that the courierimapuiddb is created
#     uiddb = flexmock('uiddb')
#     uiddb.should_receive(:write).with("1 #{t.to_i} 1\n").once
#     uiddb.should_receive(:close)
#     flexstub(File).should_receive(:open).with(File.join(@name, 'courierimapuiddb'), 'w').returns(uiddb).once.ordered
#     
#     # Verify that the mailbox is subscribed
#     # subscribe = flexmock('subscribe')
#     # subscribe.should_receive(:write).with("INBOX.new_mailbox\n")
#     # subscribe.should_receive(:close)
#     # flexstub(File).should_receive(:open).with(File.join(@inbox, 'courierimapsubscribed'), 'a').returns(subscribe).once.ordered
#     
#     results = JoyentMaildir::Mailbox.create(users(:ian), 'INBOX.new_mailbox')
#     
#     assert_equal t.to_i, results[:uidvalidity]
#     assert_equal 1, results[:uidnext]
#   end
# end
# 
# context "A Trash box" do
#   include FlexMock::TestCase
#   fixtures all_fixtures
#   
#   specify "can be emptied" do
#     trash = JoyentMaildir::MaildirPath.build('joyent.joyent.com', 'ian', 'INBOX.Trash')
#     flexstub(Dir).should_receive(:[]).with("#{trash}/*").once.returns {
#       ['.', '..', '/foo/bar/baz', '/a/b/c']
#     }
#     flexstub(FileUtils).should_receive(:rm).with('.', :force => true).never
#     flexstub(FileUtils).should_receive(:rm).with('..', :force => true).never
#     flexstub(FileUtils).should_receive(:rm).with('/foo/bar/baz', :force => true).once
#     flexstub(FileUtils).should_receive(:rm).with('/a/b/c', :force => true).once
#     
#     JoyentMaildir::Mailbox.empty_trash(users(:ian))
#   end
# end
# 
# context "A mailbox" do  
#   include FlexMock::TestCase
#   fixtures all_fixtures
#   
#   specify "default test" do
#   end
# 
#   # I implemented copy but we don't actually provide that capability.  Rather
#   # than remove it entirely, I'll comment it out in case we ever do.
#   # specify "can be copied" do
#   #   t = Time.now
#   #   flexstub(Time).should_receive(:now).returns(t)
#   #   
#   #   src   = JoyentMaildir::MaildirPath.build('joyent.joyent.com', 'ian', 'INBOX.delete_me')
#   #   dst   = JoyentMaildir::MaildirPath.build('joyent.joyent.com', 'ian', 'INBOX.copy')
#   #   inbox = JoyentMaildir::MaildirPath.build('joyent.joyent.com', 'ian', 'INBOX')
#   #   
#   #   # Verify that the maildir gets copied
#   #   flexstub(FileUtils).should_receive(:cp_r).with(src, dst).once.ordered
#   # 
#   #   # Verify that the new mailbox is subscribed
#   #   subscribe = flexmock('subscribe')
#   #   subscribe.should_receive(:write).with("INBOX.copy\n")
#   #   subscribe.should_receive(:close)
#   #   flexstub(File).should_receive(:open).with(File.join(inbox, 'courierimapsubscribed'), 'a').returns(subscribe).once.ordered
#   #   
#   # 
#   #   # Verify that the uiddb is updated
#   #   uiddb     = ["1 1159973875 3\n",
#   #                "2 1159907087.M314678P19340V01980007I0007604D_1.unknown,S=20866\n"]
#   #   new_uiddb = "1 #{t.to_i} 2\n1 1159907087.M314678P19340V01980007I0007604D_1.unknown,S=20866\n"
#   #            
#   #   uiddb_mock = flexmock('uiddb')
#   #   uiddb_mock.should_receive(:readlines).returns(uiddb).once.ordered(:uiddb1)
#   #   uiddb_mock.should_receive(:close)
#   #   
#   #   nuiddb_mock = flexmock('nuiddb')
#   #   nuiddb_mock.should_receive(:write).with(new_uiddb).once.ordered(:uiddb2)
#   #   nuiddb_mock.should_receive(:close)
#   #   
#   #   flexstub(File).should_receive(:open).with(File.join(dst, 'courierimapuiddb')).returns(uiddb_mock).once.ordered
#   #   # Verify that the data was properly written
#   #   flexstub(File).should_receive(:open).with(File.join(dst, 'courierimapuiddb'), 'w').returns(nuiddb_mock).once.ordered
#   #   
#   #   
#   #   results = JoyentMaildir::Mailbox.new(mailboxes(:ian_delete_me)).copy('INBOX.copy')
#   #   
#   #   assert_equal t.to_i, results[:uidvalidity]
#   #   assert_equal 2, results[:uidnext]
#   # end
# 
#   # TODO need to add append
#   # specify "can be appended to" do
#   #   raw = open(File.dirname(__FILE__)+'/../fixtures/raw_messages/raw1.txt').read
#   #   t   = Time.now
#   #   bs  = OpenStruct.new(:data => OpenStruct.new(:code => OpenStruct.new(:data => 'UID 42')))
#   #       
#   #   JoyentImap::ImapMailbox.new(mailboxes(:ian_inbox)).append(raw, t)
#   # end
# end
