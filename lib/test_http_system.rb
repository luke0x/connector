=begin #(fold)
++
Copyright 2004-2007 Joyent Inc.

Redistribution and/or modification of this code is 
governed by the GPLv2.

Report issues and contribute at http://dev.joyent.com/

$Id$
--
=end #(end)

require 'net/http'
require 'gettext/rails'

# Mock for ProductionHttpSystem
class TestHttpSystem < ProductionHttpSystem
  include GetText
  bindtextdomain('connector')
  
  class << self
    # Net::HTTPResponse
    def get_response_by_host_and_path(host, path = '', user = '', password = '', redirects_to_follow = 0)

      ret = case
            when host != "www.example.com": raise "#{_("Cannot connect to the provided host")}"
            when path != "/basic/US32Holidays.ics" && path != "/plain/Spain32Holidays.ics" && path != '/plain/UK32Holidays.ics': raise "#{_("Cannot find the required ICS Calendar. The server returns 404 - Not found")}"
            when path == "/basic/US32Holidays.ics" && (user != 'ian' || password != 'testpass'): raise "#{_("Either the provided Username or Password are not valid")}"
            when path == "/plain/UK32Holidays.ics": FakeHttpResponse.new(File.read("#{RAILS_ROOT}/test/fixtures/ical/UK32Holidays.ics"))
            when path == "/plain/Spain32Holidays.ics": FakeHttpResponse.new(File.read("#{RAILS_ROOT}/test/fixtures/ical/Spain32Holidays.ics"))
            when path == "/basic/US32Holidays.ics" && user == 'ian' && password == 'testpass': FakeHttpResponse.new(File.read("#{RAILS_ROOT}/test/fixtures/ical/US32Holidays.ics"))
            else raise "#{_("Request error with response: %{i18n_error_message}")%{:i18n_error_message => "Any other error message"}}"
            end
    end
    
  end
  
end

# This just mocks body method for fake Net::HTTPResponse
class FakeHttpResponse
  def initialize(body)
    @body = body
  end
  attr_reader :body
end