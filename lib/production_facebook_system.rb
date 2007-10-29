=begin #(fold)
++
Copyright 2004-2007 Joyent Inc.

Redistribution and/or modification of this code is 
governed by the GPLv2.

Report issues and contribute at http://dev.joyent.com/

$Id$
--
=end #(end)

class ProductionFacebookSystem                 
  cattr_accessor :logger
  @@logger = Logger.new("#{RAILS_ROOT}/log/facebook.log")
  
  def set_profile(user)
    facebook_execute(user) do |fbsession| 
      # TODO: Determine where the best place is for this markup
      fbml = "<div style=\"background-image: url(http://63.193.186.12/images/facebook/notification.png);background-position:left;background-repeat:no-repeat;padding:3px 2px 3px 22px;\">You have <a href=\"http://apps.facebook.com#{FACEBOOK['canvas_path']}\">#{user.current_notifications.size} notifications</a>."
            
      fbsession.profile_setFBML(:markup => fbml)
    end
  end              
         
  def add_news_item(title, body, user)
    facebook_execute(user) do |fbsession|
      fbsession.feed_publishStoryToUser(:title => title, :body => body)
    end
  end
  
  def add_mini_feed_item(title, body, user)     
    facebook_execute(user) do |fbsession|
      fbsession.feed_publishActionOfUser(:title => title, :body => body)
    end
  end                      
        
  private
  
  def facebook_execute(user, &block)
    if fbsession = facebook_session(user)
      begin
        yield fbsession
      rescue => e
        @@logger.error("#{Time.now.xmlschema}: #{e.message}")
        @@logger.error(e.backtrace.join("\n"))        
      end
    end
  end
  
  def facebook_session(user)
    return nil unless user.facebook?
    
    begin
      facebook_session = RFacebook::FacebookWebSession.new(FACEBOOK['key'], FACEBOOK['secret'])
      facebook_session.activate_with_previous_session(user.facebook_session_key, user.facebook_uid, 0)
      facebook_session
    rescue => e
      @@logger.error("#{Time.now.xmlschema}: #{e.message}")
      @@logger.error(e.backtrace.join("\n"))        
    end
  end
end
