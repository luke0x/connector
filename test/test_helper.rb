=begin #(fold)
++
Copyright 2004-2007 Joyent Inc.

Redistribution and/or modification of this code is 
governed by the GPLv2.

Report issues and contribute at http://dev.joyent.com/

$Id$
--
=end #(end)

ENV["RAILS_ENV"] = "test"

require File.expand_path(File.dirname(__FILE__) + "/../config/environment")
require 'test_help'
require File.expand_path(File.dirname(__FILE__) + "/integration_dsl")
require File.expand_path(File.dirname(__FILE__) + "/joyent_assertions")

# By default, we mock the file system.
MockFS.mock = true
MockFS.mock_file_system.clone_real_directory_under JoyentConfig.storage_root, File.expand_path(File.dirname(__FILE__) + '/fixtures/storage_root')
MockFS.mock_file_system.clone_real_directory_under "#{RAILS_ROOT}/public/images/icons/", "#{RAILS_ROOT}/public/images/icons/"
MockFS.mock_file_system.clone_real_directory_under "/home/vmail", File.expand_path(File.dirname(__FILE__)) + '/fixtures/mail_root'

class Test::Unit::TestCase
  include JoyentAssertions

  # Transactional fixtures accelerate your tests by wrapping each test method
  # in a transaction that's rolled back on completion.  This ensures that the
  # test database remains unchanged so your fixtures don't have to be reloaded
  # between every test method.  Fewer database queries means faster tests.
  #
  # Read Mike Clark's excellent walkthrough at
  #   http://clarkware.com/cgi/blosxom/2005/10/24#Rails10FastTesting
  #
  # Every Active Record database supports transactions except MyISAM tables
  # in MySQL.  Turn off transactional fixtures in this case; however, if you
  # don't care one way or the other, switching from MyISAM to InnoDB tables
  # is recommended.
  self.use_transactional_fixtures = true

  # Instantiated fixtures are slow, but give you @david where otherwise you
  # would need people(:david).  If you don't want to migrate your existing
  # test cases which use the @david style and don't mind the speed hit (each
  # instantiated fixtures translates to a database query per test method),
  # then set this back to true.
  self.use_instantiated_fixtures  = false
  
  
  # DO NOT CHANGE, THIS IS BLACK MAGIC
  if method_defined?(:setup)
    alias_method :pre_mock_fixtures_setup, :setup
    define_method(:setup) do
      pre_mock_fixtures_setup
      MockFS.mock_file_system.begin
    end
  end
  
  if method_defined?(:teardown)
    alias_method :pre_mock_fixtures_teardown, :teardown
    define_method(:teardown) do
      pre_mock_fixtures_teardown
      MockFS.mock_file_system.rollback!
    end
  end
  
  def self.method_added(amethod)
    case amethod.to_s
    when 'setup'
      unless method_defined?(:pre_mock_setup)
        alias_method :pre_mock_setup, :setup
        define_method(:setup) do
          MockFS.mock_file_system.begin
          pre_mock_fixtures_setup
          pre_mock_setup
        end
      end
    when 'teardown'
      unless method_defined?(:pre_mock_teardown)
        alias_method :pre_mock_teardown, :teardown
        define_method(:teardown) do
          pre_mock_fixtures_teardown
          pre_mock_teardown
          MockFS.mock_file_system.rollback!
        end
      end
    end
  end
  # END DO NOT CHANGE
  

  # Add more helper methods to be used by all tests here...
  def self.all_fixtures
    [:addresses, :bookmarks, :bookmark_folders, :calendars, :comments, :contact_lists,
     :domains, :email_addresses, :events, :folders, :identities, :im_addresses, :invitations,
     :joyent_files, :login_tokens, :mailboxes, :messages, :notifications, :organizations,
     :people, :permissions, :phone_numbers, :quotas, :reports,
     :report_descriptions, :smart_groups, :smart_group_attributes, :affiliates,
     :smart_group_attribute_descriptions, :smart_group_descriptions, :special_dates, :lists,
     :list_cells, :list_columns, :list_rows, :list_folders, :taggings, :tags, :users, :user_options, 
     :user_requests, :websites, :subscriptions, :mail_aliases, :mail_alias_memberships]
  end                         

  def login_person(user)
    @request.session[:sso_verified] = true
    @request.cookies['sso_token_value'] = users(user).create_login_token.value
    @request.host = users(user).person.organization.domains.first.web_domain
    User.current = users(user)
    LoginToken.current = users(user).login_token
  end
  
  def http_login_person(user)
    u = users(user)
    @request.env["HTTP_AUTHORIZATION"] = "Basic " + Base64.encode64("#{u.username}:#{u.plaintext_password}")
    @request.host = u.person.organization.domains.first.web_domain
  end

  # Used for integration testing
  def new_session(host)
    h = host.is_a?(Symbol) ? domains(host).web_domain : host
    host! h
    open_session do |sess|
      sess.host = h
      sess.extend(IntegrationDSL)
      yield sess if block_given?
    end
  end
  
  def new_session_as(user)
    h = users(user).organization.domains.first.web_domain
    host! h
    new_session(host) do |sess|
      sess.host = h
      sess.goes_to_login
      sess.logs_in_as(user)
      yield sess if block_given?
    end
  end
  
  def vcard_fixture(name)
    File.read("#{RAILS_ROOT}/test/fixtures/vcards/#{name}.vcf")
  end
  
  def file_fixture(path)
    File.read("#{RAILS_ROOT}/test/fixtures/storage_root/#{path}")
  end

  # for general files in the fixtures/files dir
  def joyent_file_fixture(path)
    File.read("#{RAILS_ROOT}/test/fixtures/files/#{path}")
  end
  
  def ical_fixture(name)
    File.read("#{RAILS_ROOT}/test/fixtures/ical/#{name}.ics")
  end
  
  def opml_fixture(name)
    File.read("#{RAILS_ROOT}/test/fixtures/opml/#{name}.opml")
  end

  # load a named fixture file from a per-controller subdirectory
  def method_missing(selector, *args)
    if selector.to_s =~ /(.+)_fixture/
      dirname = $1
      return YAML::load(ERB.new(File.read("#{RAILS_ROOT}/test/fixtures/#{dirname}/#{args[0]}.yml")).result)
    end
    return super
  end
  
  def localize_time(time)
    if User.current && time
      User.current.person.tz.utc_to_local(time)
    else
      time
    end
  end
  
  def normalize_time(time)
    if User.current && time
      User.current.person.tz.local_to_utc(time)
    else
      time
    end
  end
  
  # this loads the recurrence description class and returns a hash based on freq to replace fixtures
  Rd = RecurrenceDescription.new(:name, :rule_text, :id, :seconds_to_increment, :advance_arguments)
  def recurrence_descriptions(freq)
    Rd.descriptions(freq)
  end
  
  def fill_root_paths
    User.find(:all).each do |u|
      MockFS.fill_path u.root_path
    end
  end
end