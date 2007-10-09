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

context "Mailbox syncing - special mailboxes" do
  include FlexMock::TestCase
  fixtures all_fixtures
  
  def setup
    Mailbox.destroy_all # Start with no proxies
  end
  
  specify "empty" do
  end

  # specify "creates specials in maildir and db if it does not exist in imap" do
  #   t = Time.now
  #   flexstub(Time).should_receive(:now).returns(t)
  #   
  #   sent   = JoyentMaildir::MaildirPath.build('joyent.joyent.com', 'ian', 'INBOX.Sent')
  #   trash  = JoyentMaildir::MaildirPath.build('joyent.joyent.com', 'ian', 'INBOX.Trash')
  #   drafts = JoyentMaildir::MaildirPath.build('joyent.joyent.com', 'ian', 'INBOX.Drafts')
  #   flexstub(File).should_receive(:exist?).with(sent).once.returns(false)
  #   flexstub(File).should_receive(:exist?).with(trash).once.returns(false)
  #   flexstub(File).should_receive(:exist?).with(drafts).once.returns(false)
  #   
  #   
  #   flexstub(JoyentMaildir::Mailbox).should_receive(:create).with(users(:ian), 'INBOX.Sent').once.returns({:uidvalidity   => t.to_i, :uidnext => 1})
  #   flexstub(JoyentMaildir::Mailbox).should_receive(:create).with(users(:ian), 'INBOX.Trash').once.returns({:uidvalidity  => t.to_i, :uidnext => 1})
  #   flexstub(JoyentMaildir::Mailbox).should_receive(:create).with(users(:ian), 'INBOX.Drafts').once.returns({:uidvalidity => t.to_i, :uidnext => 1})
  #   
  #   JoyentMaildir::MailboxSync.sync_for(users(:ian))
  #   
  #   assert(mb = Mailbox.find_by_user_id_and_full_name(users(:ian).id, 'INBOX.Sent'))
  #   assert_equal t.to_i, mb.uid_validity
  #   assert_equal 1, mb.uid_next
  # 
  #   assert(mb = Mailbox.find_by_user_id_and_full_name(users(:ian).id, 'INBOX.Trash'))
  #   assert_equal t.to_i, mb.uid_validity
  #   assert_equal 1, mb.uid_next
  # 
  #   assert(mb = Mailbox.find_by_user_id_and_full_name(users(:ian).id, 'INBOX.Drafts'))
  #   assert_equal t.to_i, mb.uid_validity
  #   assert_equal 1, mb.uid_next
  # end
end


# context "Mailbox syncing - new and removed maildir mailboxes" do
#   include FlexMock::TestCase
#   fixtures all_fixtures
#   
#   specify "creates Mailbox objects for new imap mailboxes" do
#     JoyentImap::MailboxSync.sync_for(users(:ian))
#     
#     assert(mb = users(:ian).mailboxes.find_by_full_name('INBOX.not_in_db'))
#     assert_equal 1155753336, mb.uid_validity
#     assert_equal 1, mb.uid_next
#   end
#   
#   specify "creates Mailbox objects for new imap mailboxes that have tagged messages" do
#     JoyentImap::MailboxSync.sync_for(users(:ian))
#     
#     assert(mb = users(:ian).mailboxes.find_by_full_name('INBOX.not_in_db'))
#     assert_equal 1155753336, mb.uid_validity
#     assert_equal 1, mb.uid_next    
#   end
#   
#   specify "destroys Mailbox objects when the mailbox is no longer in imap" do
#     users(:ian).mailboxes.create(:full_name => 'INBOX.not_in_imap', :uid_validity => 23456, :uid_next => 1)
#     
#     JoyentImap::MailboxSync.sync_for(users(:ian))
#     
#     assert_nil users(:ian).mailboxes.find_by_full_name('INBOX.not_in_imap')
#   end
# end
# 
# context "Mailbox syncing - copied and moved imap mailboxes" do
#   include FlexMock::TestCase
#   fixtures all_fixtures
#   
#   specify "a mailbox copied via imap preserves permissions" do
#     dbmailboxes = Mailbox.find(:all).map do |mb|
#       OpenStruct.new(:name => mb.full_name)
#     end
#     dbmailboxes << OpenStruct.new(:name => 'INBOX.base_copy')
#     
#     JoyentImap::MailboxSync.sync_for(users(:ian))
#     
#     assert(mb = Mailbox.find_by_full_name('INBOX.base_copy'))
#     assert mb.has_permissions?
#   end
#   
#   specify "a mailbox moved via imap preserves permissions" do
#     dbmailboxes = Mailbox.find(:all, :conditions => ["full_name != 'INBOX.base'"]).map do |mb|
#       OpenStruct.new(:name => mb.full_name)
#     end
#     dbmailboxes << OpenStruct.new(:name => 'INBOX.base_moved')
# 
#     JoyentImap::MailboxSync.sync_for(users(:ian))
# 
#     assert_nil Mailbox.find_by_full_name('INBOX.base')
#     assert(mb = Mailbox.find_by_full_name('INBOX.base_moved'))
#     assert mb.has_permissions?
#   end
# end