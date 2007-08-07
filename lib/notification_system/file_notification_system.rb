module NotificationSystem
  class FileNotificationSystem
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