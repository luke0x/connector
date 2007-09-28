=begin #(fold)
Copyright 2004-2007 Joyent Inc.

Redistribution and/or modification of this code is governed
by either the GPLv2 or Joyent Commercial Software licenses.

Report issues and contribute at http://dev.joyent.com/

$Id$
=end #(end)

class SystemMailer < ActionMailer::Base
  def welcome_email(user)
    recipients user.recovery_email || user.system_email
    subject "Welcome to the Connector"
    body({"user" => user})
    from "support@joyent.com"
  end
  
  def guest_welcome_email(user)
    recipients user.recovery_email
    subject "Welcome to the Connector"
    body({"user" => user})
    from "support@joyent.com"
  end
  
  def reset_password(user)
    recipients user.recovery_email
    subject "Connector password reset"
    body({"user" => user})
    from "support@joyent.com"
  end

  def generated_password(user)
    recipients user.recovery_email
    subject "Connector password reset"
    body({"user" => user})
    from "support@joyent.com"
  end
    
  def over_quota(user)
    recipients user.recovery_email || user.system_email
    bcc JoyentConfig.quota_email_list
    subject "Your Connector account is over the quota"
    body({"user" => user})
    from "support@joyent.com"
  end
  
  def near_quota(user)
    recipients user.recovery_email || user.system_email
    bcc JoyentConfig.quota_email_list
    subject "Your Connector account is nearing the quota"
    body({"user" => user})
    from "support@joyent.com"
  end
  
  def report_issue(message)
    recipients JoyentConfig.exception_recipients
    subject "Message Rendering Report for Message #{message.id}"
    from "messagerender@joyent.com"
    body({'message' => message})
    
    attachment :content_type => 'text/plain',
               :body         => message.raw,
               :filename     => message.filename
  end
end
