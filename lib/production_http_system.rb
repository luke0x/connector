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

# Custom Net::HTTP requests with localizations for some
# of the most frequent problems with URLs provided by application users
class ProductionHttpSystem
  include GetText
  bindtextdomain('connector')
  
  class << self
    # Net::HTTPResponse
    def get_response_by_url(url, user = '', password = '', redirects_to_follow = 0)
      begin
        parsed = URI.parse(url)
      rescue URI::InvalidURIError
        raise "#{_("The provided URL is not valid")}"
      end
      unless (parsed.scheme == 'http' || parsed.scheme == 'https')
        raise "#{_("Only http and https protocols supported")}"
      end  
      response = self.get_response_by_host_and_path(parsed.host, parsed.path, user, password, redirects_to_follow)
    end

    # Net::HTTPResponse
    def get_response_by_host_and_path(host, path = '', user = '', password = '', redirects_to_follow = 0)

      # Maybe is redundant, but want to ensure that we're not going to allow
      # more redirections than the allowed in JoyentConfig
      if redirects_to_follow > JoyentConfig.http_max_redirects
        redirects_to_follow = JoyentConfig.http_max_redirects
      end

      begin
        Net::HTTP.start(host) {|http|
          req = Net::HTTP::Get.new(path)
          unless user.blank?
            req.basic_auth user, password
          end
          
          http.read_timeout = JoyentConfig.http_read_timeout
          
          response = http.request(req)
          
          case response
          when Net::HTTPSuccess
            return response
          # Eventually, following redirections
          when Net::HTTPRedirection
            return self.get_response_by_url(response['location'], user, password, redirects_to_follow - 1)
          # Most common problems?. Would like to localize, at least, the most frequent problems
          when Net::HTTPUnauthorized
            raise "#{_("Either the provided Username or Password are not valid")}"
          when Net::HTTPNotFound
            raise "#{_("Cannot find the required ICS Calendar. The server returns 404 - Not found")}"
          else # Catch whatever the error
            begin
              response.value
            rescue Exception => e
              raise "#{_("Request error with response: %{i18n_error_message}")%{:i18n_error_message => "#{e.message}"}}"
            end
          end

        }
      rescue SocketError
        raise "#{_("Cannot connect to the provided host")}"
      end
    end
    
  end
  
end