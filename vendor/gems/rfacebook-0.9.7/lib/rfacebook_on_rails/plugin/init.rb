# Copyright (c) 2007, Matt Pizzimenti (www.livelearncode.com)
# All rights reserved.
# 
# Redistribution and use in source and binary forms, with or without modification,
# are permitted provided that the following conditions are met:
# 
# Redistributions of source code must retain the above copyright notice,
# this list of conditions and the following disclaimer.
# 
# Redistributions in binary form must reproduce the above copyright notice,
# this list of conditions and the following disclaimer in the documentation
# and/or other materials provided with the distribution.
# 
# Neither the name of the original author nor the names of contributors
# may be used to endorse or promote products derived from this software
# without specific prior written permission.
# 
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
# AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
# IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
# ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE
# LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
# DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
# SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
# CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
# OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
# OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
#

require "rfacebook_on_rails/view_extensions"
require "rfacebook_on_rails/controller_extensions"
require "rfacebook_on_rails/model_extensions"
require "rfacebook_on_rails/session_extensions"

module RFacebook::Rails::Plugin
  
  module ControllerExtensions
    def facebook_api_key
      # TODO: pull these overrides up into the original module, and make a FACEBOOK global in the backwards-compatibility file
      FACEBOOK["key"] || super
    end
    def facebook_api_secret
      FACEBOOK["secret"] || super
    end
    def facebook_canvas_path
      FACEBOOK["canvas_path"] || super
    end
    def facebook_callback_path
      FACEBOOK["callback_path"] || super
    end
  end  

  module ModelExtensions
    def facebook_api_key
      FACEBOOK["key"] || super
    end
    def facebook_api_secret
      FACEBOOK["secret"] || super
    end
  end

  module ViewExtensions
  end
  
end

# inject methods to Rails MVC classes
ActionView::Base.send(:include, RFacebook::Rails::ViewExtensions)
ActionView::Base.send(:include, RFacebook::Rails::Plugin::ViewExtensions)

ActionController::Base.send(:include, RFacebook::Rails::ControllerExtensions)
ActionController::Base.send(:include, RFacebook::Rails::Plugin::ControllerExtensions)

ActiveRecord::Base.send(:include, RFacebook::Rails::ModelExtensions)
ActiveRecord::Base.send(:include, RFacebook::Rails::Plugin::ModelExtensions)

# inject methods to Rails session management classes
CGI::Session.send(:include, RFacebook::Rails::SessionExtensions)

# TODO: document SessionStoreExtensions as API so that anyone can patch their own custom session container in addition to these
CGI::Session::PStore.send(:include, RFacebook::Rails::SessionStoreExtensions)
CGI::Session::ActiveRecordStore.send(:include, RFacebook::Rails::SessionStoreExtensions)
CGI::Session::DRbStore.send(:include, RFacebook::Rails::SessionStoreExtensions)
CGI::Session::FileStore.send(:include, RFacebook::Rails::SessionStoreExtensions)
CGI::Session::MemoryStore.send(:include, RFacebook::Rails::SessionStoreExtensions)
begin
  CGI::Session::MemCacheStore.send(:include, RFacebook::Rails::SessionStoreExtensions)
rescue
  RAILS_DEFAULT_LOGGER.debug "** RFACEBOOK INFO: It looks like you don't have memcache-client, so MemCacheStore was not extended"
end

# load Facebook configuration file (credit: Evan Weaver)
begin
  yamlFile = YAML.load_file("#{RAILS_ROOT}/config/facebook.yml")
rescue Exception => e
  raise StandardError, "config/facebook.yml could not be loaded."
end

if yamlFile
  if yamlFile[RAILS_ENV]
    FACEBOOK =  yamlFile[RAILS_ENV]
  else
    raise StandardError, "config/facebook.yml exists, but doesn't have a configuration for RAILS_ENV=#{RAILS_ENV}."
  end
else
  raise StandardError, "config/facebook.yml does not exist."
end

# parse for full URLs in facebook.yml (multiple people have made this mistake)
def ensureRelativePath(path)
  if matchData = /(\w+)(\:\/\/)([\w0-9\.]+)([\:0-9]*)(.*)/.match(path)
    relativePath = matchData.captures[4]
    RAILS_DEFAULT_LOGGER.debug "** RFACEBOOK INFO: It looks like you used a full URL (#{path}) in facebook.yml.  RFacebook expected a relative path and has automatically converted this URL to #{relativePath}."
    return relativePath
  else
    return path
  end
end

FACEBOOK["canvas_path"] = ensureRelativePath(FACEBOOK["canvas_path"])
FACEBOOK["callback_path"] = ensureRelativePath(FACEBOOK["callback_path"])

# make sure the paths have leading and trailing slashes
def ensureLeadingAndTrailingSlashesForPath(path)
  if (path and path.size>0)
    if !path.starts_with?("/")
      path = "/#{path}"
    end
    if !path.reverse.starts_with?("/")
      path = "#{path}/"
    end
    return path.strip
  else
    return nil
  end
end

FACEBOOK["canvas_path"] = ensureLeadingAndTrailingSlashesForPath(FACEBOOK["canvas_path"])
FACEBOOK["callback_path"] = ensureLeadingAndTrailingSlashesForPath(FACEBOOK["callback_path"])