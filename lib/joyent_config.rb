=begin #(fold)
Copyright 2004-2007 Joyent Inc.

Redistribution and/or modification of this code is governed
by either the GPLv2 or Joyent Commercial Software licenses.

Report issues and contribute at http://dev.joyent.com/

$Id$
=end #(end)

# This class is only to be referenced in the environment files
require 'etc'

class JoyentConfig
  def self.config_value(name, default)
    cattr_accessor name
    self.send("#{name}=", default)
  end

  config_value :mongrel_cluster_host, 'hostname'
  config_value :asset_host, [1, 2, 3, 4].map{|i| "assets#{i}.domain"}

  config_value :ldap_host, 'hostname'
  config_value :ldap_password, 'password'
  config_value :base_dn, 'dc=example,dc=com'
  config_value :admin_dn, 'uid=admin,dc=example,dc=com'

  config_value :search_host, 'hostname'
  config_value :search_port, '1978'
  config_value :search_user, 'username'
  config_value :search_password, 'password'

  config_value :imap_host, 'hostname'
  config_value :imap_remove_script, '/opt/joyent/systems/remove_maildir'
  config_value :smtp_host, 'hostname'
  
  config_value :maildir_worker_host, 'hostname'
  config_value :maildir_worker_port, '22222'

  config_value :production_search_system_host, 'hostname'
  config_value :production_search_system_port, '2222'

  config_value :joyent_job_host, 'hostname'
  config_value :joyent_job_port, '6666'

  config_value :bookmark_generator_request_hosts, ['hostname1'] # must contain the request host's mongrel_cluster_host
  config_value :bookmark_generator_host, 'hostname'
  config_value :bookmark_generator_port, '6690'
  config_value :bookmark_generator_webkit2png_path, '/opt/local/bin/webkit2png'
  config_value :bookmark_generator_save_prefix, '/opt/joyent/connector/bookmarks/'

  config_value :storage_root, '/home/data/'
  
  # /etc/ssh/ssh_host_rsa_key.pub (remove the email address at the end AND add the server at the beginning)      
  config_value :ssh_public_key, 'ssh public key'
  config_value :strongspace_domain, 'hostname'
  
  config_value :jajah_affiliate_id,            'affiliate id'
  config_value :jajah_call_service_wsdl_uri,   'https://www.jajah.com/api/CallService.asmx?WSDL'
  config_value :jajah_member_service_wsdl_uri, 'https://www.jajah.com/api/MemberServices.asmx?WSDL'

  config_value :page_limit, 100
  
  config_value :disk_usage_diff_file, File.join(JoyentConfig.storage_root, '.joyent', 'org_disk_usage.diff')
  config_value :disk_usage_new_file,  File.join(JoyentConfig.storage_root, '.joyent', 'org_disk_usage.txt')
  config_value :disk_usage_old_file,  File.join(JoyentConfig.storage_root, '.joyent', 'org_disk_usage.txt.old')
  
  config_value :quota_warning_percentage, 0.90
  config_value :quota_email_list, ['user@domain']
  
  # Default to process's uid/gid.  Production.rb sets it to 'vmail' user.
  config_value :maildir_owner, Process.uid
  config_value :maildir_group, Process.gid
  
  # Admin Controller SHA1 Hashes
  config_value :admin_http_user,       'userhash'
  config_value :admin_http_password,   'passwordhash'
  config_value :admin_secure_password, 'password2hash'
  
  # API Authentication Info
  config_value :api_user,     'username'
  config_value :api_password, 'password'
  
  # Bookmark Generator
  config_value :bookmark_notification_list, ['username@example.com']
  config_value :bookmark_email_from,        "Bookmark Monitor <username@example.com>"

  config_value :organization_ssh_public_key, "org ssh public key"

  config_value :user_aes_salt, "aes salt"
  config_value :user_new_password_salt, "password salt"
  
  config_value :login_token_new_salt, "another salt"
end
