=begin #(fold)
++
Copyright 2004-2007 Joyent Inc.

Redistribution and/or modification of this code is 
governed by the GPLv2.

Report issues and contribute at http://dev.joyent.com/

$Id$
--
=end #(end)

# This is the drb process that manages everything.
# It receives requests from the application process(es).

require 'drb'

module JoyentMaildir
  class MaildirWorker
    include DRbUndumped

  
    # Mailbox.list
    def mailbox_list(user_id)
      JoyentMaildir::MailboxSync.sync_for(User.find(user_id))
    end
    
    # Mailbox.empty_spam
    def mailbox_empty_spam(user_id)
      JoyentMaildir::Mailbox.empty_spam(User.find(user_id))
    end
  
    # Mailbox.empty_trash
    def mailbox_empty_trash(user_id)
      JoyentMaildir::Mailbox.empty_trash(User.find(user_id))
    end
  
    # Mailbox#sync
    def mailbox_sync(mailbox_id)
      JoyentMaildir::MessageSync.sync_for(::Mailbox.find(mailbox_id))
    end
  
    # Mailbox#count
    def mailbox_count(mailbox_id)
      JoyentMaildir::Mailbox.new(::Mailbox.find(mailbox_id)).count
    end
  
    # Mailbox#create_child
    def mailbox_create_child(user_id, child_name)
      JoyentMaildir::Mailbox.create(User.find(user_id), child_name)
    end
  
    # Mailbox#rename!
    def mailbox_rename(mailbox_id, name)
      JoyentMaildir::Mailbox.new(::Mailbox.find(mailbox_id)).rename(name)
    end
  
    # Mailbox#delete!
    def mailbox_delete(mailbox_id)
      JoyentMaildir::Mailbox.new(::Mailbox.find(mailbox_id)).delete
    end
  
    # Mailbox#append
    def mailbox_append(mailbox_id, message)
      JoyentMaildir::Mailbox.new(::Mailbox.find(mailbox_id)).append(message)
    end
  

    # Message#maildir_message
    def message_maildir_message(message_id)
      JoyentMaildir::Message.new(::Message.find(message_id)).fetch
    end

    def message_parsed_message(message_id)
      JoyentMaildir::Message.new(::Message.find(message_id)).parsed
    end
    
    def message_body(message_id, text_only=false)
      JoyentMaildir::Message.new(::Message.find(message_id)).body(text_only)
    end

    # Message#exist?
    def message_exist?(message_id)
      begin
        JoyentMaildir::Message.new(::Message.find(message_id)).exist?
      rescue JoyentMaildir::MaildirFileNotFound
        false
      end
    end
  
    # Message#delete!
    def message_delete(message_id)
      JoyentMaildir::Message.new(::Message.find(message_id)).delete
    end
  
    # Message#copy_to
    def message_copy_to(message_id, mailbox_id)
      JoyentMaildir::Message.new(::Message.find(message_id)).copy_to(::Mailbox.find(mailbox_id))
    end
  
    # Message#move_to
    def message_move_to(message_id, mailbox_id)
      JoyentMaildir::Message.new(::Message.find(message_id)).move_to(::Mailbox.find(mailbox_id))    
    end
  
    # Message#seen!
    def message_seen(message_id)
      JoyentMaildir::Message.new(::Message.find(message_id)).seen
    end
  
    # Message#flag!
    def message_flag(message_id)
      JoyentMaildir::Message.new(::Message.find(message_id)).flag
    end

    # Message#unflag!
    def message_unflag(message_id)
      JoyentMaildir::Message.new(::Message.find(message_id)).unflag
    end

    # Message#draft!
    def message_draft(message_id)
      JoyentMaildir::Message.new(::Message.find(message_id)).draft
    end
    
    # Message#answered!
    def message_answered(message_id)
      JoyentMaildir::Message.new(::Message.find(message_id)).answered
    end
    
    # Message#forwarded!
    def message_forwarded(message_id)
      JoyentMaildir::Message.new(::Message.find(message_id)).forwarded
    end
  
    # Message#raw
    def message_raw(message_id)
      JoyentMaildir::Message.new(::Message.find(message_id)).raw    
    end   
    
    # Message#update_time
    def message_update_time(message_id, time)
      JoyentMaildir::Message.new(::Message.find(message_id)).update_time(time)
    end   
  end
end