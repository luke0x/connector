=begin #(fold)
++
Copyright 2004-2007 Joyent Inc.

Redistribution and/or modification of this code is 
governed by the GPLv2.

Report issues and contribute at http://dev.joyent.com/

$Id$
--
=end #(end)

require 'ostruct'

module JoyentMaildir
  class MockMaildirWorker
  
    # Mailbox.list
    def mailbox_list(user_id)
    end

    # Mailbox.empty_spam
    def mailbox_empty_spam(user_id)
    end

    # Mailbox.empty_spam
    def mailbox_empty_spam(user_id)
    end
  
    # Mailbox.empty_trash
    def mailbox_empty_trash(user_id)
    end
  
    # Mailbox#sync
    def mailbox_sync(mailbox_id)
    end
  
    # Mailbox#count
    def mailbox_count(mailbox_id)
      OpenStruct.new(:messages => 0, :unseen => 7)
    end
  
    # Mailbox#create_child
    def mailbox_create_child(user_id, child_name)
      {:uidvalidity => Time.now.to_i, :uidnext => 1}
    end
  
    # Mailbox#rename!
    def mailbox_rename(mailbox_id, name)
      {:uidvalidity => Time.now.to_i, :uidnext => 1}
    end

    # Mailbox#delete!
    def mailbox_delete(mailbox_id)
    end
  
    # Mailbox#append
    def mailbox_append(mailbox_id, message)
    end
  
    # Message#maildir_message
    def message_maildir_message(message_id)
      fixture = File.dirname(__FILE__) + '/../../test/fixtures/raw_messages/raw1.txt'
      OpenStruct.new MailParser.parse_message(File.open(fixture))
    end
  
    # Message#exit?
    def message_exist?(message_id)
      true
    end
  
    # Message#delete!
    def message_delete(message_id)
    end
  
    # Message#copy_to
    def message_copy_to(message_id, mailbox_id)
    end
  
    # Message#move_to
    def message_move_to(message_id, mailbox_id)
    end
  
    # Message#seen!
    def message_seen(message_id)
    end
  
    # Message#flag!
    def message_flag(message_id)
    end

    # Message#unflag!
    def message_flag(message_id)
    end
  
    # Message#raw
    def message_raw(message_id)
    end
  end
end