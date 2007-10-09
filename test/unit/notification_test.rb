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

class NotificationTest < Test::Unit::TestCase
  fixtures all_fixtures
  include CRUDTest

  crud_data 'organization_id' => 1,
            'notifiee_id'     => 1,
            'notifier_id'     => 2,
            'item_id'         => 1,
            'item_type'       => 'JoyentFile',
            'acknowledged'    => false
  
  crud_required 'organization_id', 'notifiee_id', 'notifier_id', 'item_id', 'item_type'
                       
  def setup
    User.current = users(:ian)    
  end
  
  def test_acknowledge
    n = notifications(:ian_check_it)
    n.acknowledge!
    n.reload
    assert n.acknowledged?
  end  
  
  def test_notify   
    NotificationSystem::SmsNotifier.message_queue.clear
    NotificationSystem::JabberNotifier.message_queue.clear
    NotificationSystem::EmailNotifier.message_queue.clear
    
    assert_equal 0, NotificationSystem::SmsNotifier.message_queue.size
    assert_equal 0, NotificationSystem::JabberNotifier.message_queue.size
    assert_equal 0, NotificationSystem::EmailNotifier.message_queue.size    
                                
    Notification.create(:organization_id => 1, :notifiee_id => 1, :notifier_id => 1, :item_id => 1, :item_type => 'JoyentFile')    
    
    assert_equal 1, NotificationSystem::SmsNotifier.message_queue.size
    assert_equal 1, NotificationSystem::JabberNotifier.message_queue.size
    assert_equal 1, NotificationSystem::EmailNotifier.message_queue.size    
  end 
end
           
# Adding a way to know about the notification systems being invoked
module NotificationSystem
  class SmsNotifier
    cattr_accessor :message_queue
    @@message_queue = []
    
    private
    def self.send_messages(tmail, recipients)   
      message_queue << [tmail, recipients]
    end
  end
                        
  class JabberNotifier
    cattr_accessor :message_queue
    @@message_queue = []
    
    private
    def self.send_message(options)
      message_queue << options
    end
  end
  
  class EmailNotifier
    cattr_accessor :message_queue
    @@message_queue = []
    
    private
    def self.send_message(options)
      message_queue << options
    end
  end
end