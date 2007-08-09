# Copyright 2004-2007 Joyent Inc.
# 
# Redistribution and/or modification of this code is governed
# by either the GPLv2 or Joyent Commercial Software licenses.
# 
# Report issues and contribute at http://dev.joyent.com/
# 
# $Id$
module NotificationSystem
  class FileNotifier
    cattr_accessor :base_path
    @@base_path = "/tmp"
  
    def self.notify(notification)
      recipient = notification.notifiee
      sender    = notification.notifier
      
      File.open(File.join(@@base_path, notification.item.name), 'a') do |file|
        file.write("#{notification.item.class_humanize}: #{notification.message}")
        file.write("\n")
      end
    end
  end
end