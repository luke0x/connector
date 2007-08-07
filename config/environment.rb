=begin #(fold)
Copyright 2004-2007 Joyent Inc.

Redistribution and/or modification of this code is governed
by either the GPLv2 or Joyent Commercial Software licenses.

Report issues and contribute at http://dev.joyent.com/

$Id$
=end #(end)

# Be sure to restart your web server when you modify this file.
ENV['TZ'] = 'UTC'

# Uncomment below to force Rails into production mode when 
# you don't control web/app server and can't set it the proper way
# ENV['RAILS_ENV'] ||= 'production'

# Specifies gem version of Rails to use when vendor/rails is not present
RAILS_GEM_VERSION = '1.2.1' unless defined? RAILS_GEM_VERSION

# Bootstrap the Rails environment, frameworks, and default configuration
require File.join(File.dirname(__FILE__), 'boot')

Rails::Initializer.run do |config|
  # Settings in config/environments/* take precedence over those specified here
  
  # Skip frameworks you're not going to use (only works if using vendor/rails)
  config.frameworks -= [ :action_web_service ]

  # Only load the plugins named here, by default all plugins in vendor/plugins are loaded
  # config.plugins = %W( exception_notification ssl_requirement )

  # Add additional load paths for your own custom dirs
  config.load_paths += %W( #{RAILS_ROOT}/app/models/report_fetchers/ )

  # Force all environments to use the same logger level 
  # (by default production uses :info, the others :debug)
  # config.log_level = :debug

  # Use the database for sessions instead of the file system
  # (create the session table with 'rake db:sessions:create')
  config.action_controller.session_store = :active_record_store

  # Use SQL instead of Active Record's schema dumper when creating the test database.
  # This is necessary if your schema can't be completely dumped by the schema dumper, 
  # like if you have constraints or database-specific column types
  # config.active_record.schema_format = :sql

  # Activate observers that should always be running
  config.active_record.observers = :organization_observer, :user_observer,
                                   :calendar_observer, :folder_observer,
                                   :message_observer, :person_observer,
                                   :ldap_organization_observer, :ldap_domain_observer, :ldap_person_observer

  # Make Active Record use UTC-base instead of local time
  config.active_record.default_timezone = :utc
  
  # See Rails::Configuration for more options
  config.load_paths += Dir["#{RAILS_ROOT}/vendor/gems/**"].map do |dir| 
    File.directory?(lib = "#{dir}/lib") ? lib : dir
  end
end

# Add new inflection rules using the following format 
# (all these examples are active by default):
# Inflector.inflections do |inflect|
#   inflect.plural /^(ox)$/i, '\1en'
#   inflect.singular /^(ox)en/i, '\1'
#   inflect.irregular 'person', 'people'
#   inflect.uncountable %w( fish sheep )
# end

# Add new mime types for use in respond_to blocks:
# Mime::Type.register "text/richtext", :rtf
# Mime::Type.register "application/x-mobile", :mobile

# Include your application configuration below

Mime::Type.register "text/x-opml", :opml, %w( application/xml text/xml )
Mime::Type.register "text/html", :iphone

require 'tzinfo'
require 'vpim'
require 'dom_id'
require 'drb'
require 'ezcrypto'
require 'joyent_exceptions'
require 'mockfs'

ExceptionNotifier.exception_recipients = JoyentConfig.exception_recipients
ExceptionNotifier.email_prefix         = JoyentConfig.exception_email_prefix

if File.exists? "#{RAILS_ROOT}/override_config.rb"
  require 'override_config'
end

### HORRIBLE HACK
module ActionMailer
  class Base
    def perform_delivery_solaris_sendmail(mail)
      IO.popen("/opt/csw/sbin/sendmail -i -t","w+") do |sm|
        sm.print(mail.encoded.gsub(/\r/, ''))
        sm.flush
      end
    end
  end
end

ActionController::Base.fragment_cache_store = :file_store, "#{RAILS_ROOT}/tmp/cache"

class Mongrel::HttpResponse
  attr_accessor :file_to_send
  
  def custom_reset
    reset
    @header = Mongrel::HeaderOut.new(StringIO.new)
  end
end
