=begin #(fold)
++
Copyright 2004-2007 Joyent Inc.

Redistribution and/or modification of this code is 
governed by the GPLv2.

Report issues and contribute at http://dev.joyent.com/

$Id$
--
=end #(end)

namespace 'smf' do
  # This task asumes your daemons are placed at script/joyent_daemon_name
  desc "Creates a SMF Manifest for a Joyent Daemon"
  task :joyent_daemon_smf do
    unless ENV['user'] && ENV['group'] && ENV['daemon']
      puts "Usage: rake smf:joyent_daemon_smf daemon=daemon_name user=username group=groupname" 
      exit
    end
    
    working_directory = File.expand_path(RAILS_ROOT)
    user = ENV['user']
    group = ENV['group']
    daemon = ENV['daemon']
    
    # Check for the expected daemon file on script directory before to proceed
    unless File.exists?(File.expand_path("#{working_directory}/script/joyent_#{daemon}"))
      puts "No such daemon file at script/joyent_#{daemon}"
      exit 
    end
    
    File.open("#{File.expand_path("#{RAILS_ROOT}/config")}/joyent_#{daemon}-smf.xml", 'w') do |file|
      template = File.read("#{RAILS_ROOT}/config/accelerator/joyent_daemon_smf_template.erb")
      buffer = ERB.new(template).result(binding)  
      file.write buffer
    end
    
    puts "---"
    puts "SMF file created.\nEnable with:\nsudo svccfg import #{File.expand_path("#{RAILS_ROOT}/config")}/joyent_#{daemon}-smf.xml"
    puts "---"
  end
  
end