=begin #(fold)
++
Copyright 2004-2007 Joyent Inc.

Redistribution and/or modification of this code is 
governed by the GPLv2.

Report issues and contribute at http://dev.joyent.com/

$Id$
--
=end #(end)
# Can be run like this: script/runner "require RAILS_ROOT+'/script/fix_file_permissions'" --environment=production

require 'fileutils'

Organization.find(:all).each do |org|
  begin
    FileUtils.chmod_R(0750, org.root_path)
    FileUtils.chown_R('root', org.gid.to_s, org.root_path)

    org.users.each do |user|
      Dir.entries("#{user.root_path}").each do |entry|
        next if ['.', '..'].include?(entry)
        FileUtils.chmod_R(0700, "#{user.root_path}/#{entry}")
      end

      FileUtils.chmod_R(0770, user.strongspace_root_path)
      FileUtils.chmod(0700, File.join(user.strongspace_root_path, '.services'))

      FileUtils.chown_R(user.system_email, org.gid.to_s, user.strongspace_root_path)
    end
  rescue => e
    puts "ERROR - Investigate org #{org.id} - (#{e.message})"
  end
end