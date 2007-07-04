=begin #(fold)
Copyright 2004-2007 Joyent Inc.

Redistribution and/or modification of this code is governed
by either the GPLv2 or Joyent Commercial Software licenses.

Report issues and contribute at http://dev.joyent.com/

$Id$
=end #(end)

# Settings specified here will take precedence over those in config/environment.rb

# The production environment is meant for finished, "live" apps.
# Code is not reloaded between requests
config.cache_classes = true

# Use a different logger for distributed setups
# config.logger = SyslogLogger.new

# Full error reports are disabled and caching is turned on
config.action_controller.consider_all_requests_local = false
config.action_controller.perform_caching             = true

# Enable serving of images, stylesheets, and javascripts from an asset server
config.action_controller.asset_host = JoyentConfig.asset_host

# Disable delivery errors if you bad email addresses should just be ignored
config.action_mailer.raise_delivery_errors = false

#config.action_mailer.delivery_method = :solaris_sendmail

config.log_level = :info

# any refs to JoyentConfig can't be done unless it's in the 
# after_initialize block, otherwise the overrides get overridden

config.after_initialize do 
  Organization.storage_root = JoyentConfig.storage_root
  
  Person.ldap_system = ProductionLdapSystem.new(JoyentConfig.ldap_host, 
                                               JoyentConfig.admin_dn, 
                                               JoyentConfig.ldap_password, 
                                               JoyentConfig.base_dn)
                                               
  User.jajah_system  = ProductionJajahSystem.new
  
  ProductionJajahSystem.jajah_affiliate_code          = JoyentConfig.jajah_affiliate_id
  ProductionJajahSystem.jajah_call_service_wsdl_uri   = JoyentConfig.jajah_call_service_wsdl_uri
  ProductionJajahSystem.jajah_member_service_wsdl_uri = JoyentConfig.jajah_member_service_wsdl_uri
  
  MailMessage.smtp_host     = JoyentConfig.smtp_host
  
  Organization.ssh_public_key = JoyentConfig.ssh_public_key
  
  JoyentJob::Job.server     =
    DRb::DRbObject.new(nil, "druby://#{JoyentConfig.joyent_job_host}:#{JoyentConfig.joyent_job_port}")
  Bookmark.thumbnail_server =
    DRb::DRbObject.new(nil, "druby://#{JoyentConfig.bookmark_generator_host}:#{JoyentConfig.bookmark_generator_port}")

  JoyentConfig.maildir_owner = Etc.getpwnam('vmail').uid
  JoyentConfig.maildir_group = Etc.getpwnam('vmail').gid
end

ActionMailer::Base.delivery_method= :smtp

config.action_mailer.server_settings = {
  :address => '1.2.3.4',
  :port    => 25,
  :domain  => 'domain',
  :authentication => :login,
  :user_name => 'username',
  :password => 'password'
  }

# as per http://mongrel.rubyforge.org/faq.html to deal with bug in the MySQL driver
ActiveRecord::Base.verification_timeout = 14400 # mysql server set to 28800
