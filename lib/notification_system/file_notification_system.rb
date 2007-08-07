module NotificationSystem
  class FileNotificationSystem
    cattr_accessor :base_path
    @@base_path = "/tmp"
  
    def notify(users, joyent_item)
      File.open(File.join(@@base_path, recipient), 'a') do |file|
        file.write(message)
        file.write("\n")
      end
    end
  end
end