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

require "digest/md5"
require "cgi"

module RFacebook::Rails::SessionExtensions # :nodoc:
  
  # :section: New Methods
  def force_to_be_new! # :nodoc:
    @force_to_be_new = true
  end
  
  def using_facebook_session_id? # :nodoc:
    return (@fb_sig_session_id != nil)
  end
    
  # :section: Base Overrides
  
  def new_session__RFACEBOOK # :nodoc:
    if @force_to_be_new
      return true
    else
      return new_session__ALIASED
    end
  end

  def initialize__RFACEBOOK(request, options = {}) # :nodoc:
    
    # only try to use the sig when we don't have a cookie (i.e., in the canvas)
    if in_facebook_canvas?(request)
      
      # try a few different ways
      RAILS_DEFAULT_LOGGER.debug "** RFACEBOOK INFO: Attempting to use fb_sig_session_key as a session key, since we are inside the canvas"
      @fb_sig_session_id = lookup_request_parameter(request, "fb_sig_session_key")
      
      # we only want to change the session_id if we got one from the fb_sig
      if @fb_sig_session_id
        options["session_id"] = Digest::MD5.hexdigest(@fb_sig_session_id)
        RAILS_DEFAULT_LOGGER.debug "** RFACEBOOK INFO: using MD5 of fb_sig_session_key [#{options['session_id']}] for the Rails session id"
      end
    end
    
    # now call the default Rails session initialization
    initialize__ALIASED(request, options)
  end
  
  # :section: Extension Helpers
  
  def self.included(base) # :nodoc:
    base.class_eval'
      alias :initialize__ALIASED :initialize
      alias :initialize :initialize__RFACEBOOK
      
      alias :new_session__ALIASED :new_session
      alias :new_session :new_session__RFACEBOOK
    '
  end
  
  # :section: Private Helpers
  
  private
  
  # TODO: it seems that there should be a better way to just get raw parameters
  #       (not sure why the nil key bug doesn't seem to be fixed in my installation)
  #       ...also, there seems to be some interaction with Mongrel as well that can
  #       cause the parameters to fail
  def lookup_request_parameter(request, key) # :nodoc:
    
    # Depending on the user's version of Rails, this may fail due to a bug in Rails parsing of
    # nil keys: http://dev.rubyonrails.org/ticket/5137, so we have a backup plan
    begin
      
      # this should work on most Rails installations
      return request.parameters[key]
      
    rescue
      
      # this saves most other Rails installations
      begin
        
        retval = nil
        
        # try accessing raw_post (doesn't work in some mongrel installations)
        if request.respond_to?(:raw_post)
          return CGI::parse(request.send(:raw_post)).fetch(key){[]}.first
        end
        
        # try accessing the raw environment table
        if !retval
          envTable = nil
      
          envTable = request.send(:env_table) if request.respond_to?(:env_table)
          if !envTable
            envTable = request.send(:env) if request.respond_to?(:env)
          end
      
          if envTable
            # credit: Blake Carlson and David Troy
            ["RAW_POST_DATA", "QUERY_STRING"].each do |tableSource|
              if envTable[tableSource]
                retval = CGI::parse(envTable[tableSource]).fetch(key){[]}.first
              end
              break if retval
            end
          end
        end
        
        # hopefully we got a parameter
        return retval
        
      rescue
        
        # for some reason, we just can't get the parameters
        RAILS_DEFAULT_LOGGER.info "** RFACEBOOK WARNING: failed to access request.parameters"
        return nil

      end
    end
  end
  
  def in_facebook_canvas?(request) # :nodoc:
    # TODO: we should probably be checking the fb_sig for validity here (template method needed)
    #       ...we can only do this if we can grab the equivalent of a params hash
    return lookup_request_parameter(request, "fb_sig_in_canvas")
  end
    
end

# Module: SessionStoreExtensions
#
#   Special initialize method that attempts to force any session store to use the Facebook session
module RFacebook::Rails::SessionStoreExtensions # :nodoc:all
  
  # :section: Base Overrides
  
  def initialize__RFACEBOOK(session, options, *extraParams) # :nodoc:
    
    if session.using_facebook_session_id?
      
      # we got the fb_sig_session_key, so alter Rails' behavior to use that key to make a session
      begin
        RAILS_DEFAULT_LOGGER.debug "** RFACEBOOK INFO: using fb_sig_session_key for the #{self.class.to_s} session (session_id=#{session.session_id})"
        initialize__ALIASED(session, options, *extraParams)
      rescue Exception => e 
        begin
          RAILS_DEFAULT_LOGGER.debug "** RFACEBOOK INFO: failed to initialize session (session_id=#{session.session_id}), trying to force a new session"
          if session.session_id
            session.force_to_be_new!
          end
          initialize__ALIASED(session, options, *extraParams)
        rescue Exception => e
          RAILS_DEFAULT_LOGGER.debug "** RFACEBOOK INFO: failed to force a new session, falling back to default Rails behavior"
          raise e
        end
      end
      
    else
      
      # we didn't get the fb_sig_session_key, do not alter Rails' behavior
      RAILS_DEFAULT_LOGGER.debug "** RFACEBOOK INFO: using default Rails sessions (since we didn't find an fb_sig_session_key in the environment)"
      initialize__ALIASED(session, options, *extraParams)
      
    end
  end
  
  # :section: Extension Helpers
  
  def self.included(base) # :nodoc:
    base.class_eval'
      alias :initialize__ALIASED :initialize
      alias :initialize :initialize__RFACEBOOK
    '
  end
  
end
