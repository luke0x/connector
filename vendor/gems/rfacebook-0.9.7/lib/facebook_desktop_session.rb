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

require "facebook_session"

module RFacebook

class FacebookDesktopSession < FacebookSession

  ################################################################################################
  ################################################################################################
  # :section: Properties
  ################################################################################################
  
  attr_reader :session_secret # you should need this for infinite desktop sessions
  
  ################################################################################################
  ################################################################################################
  # :section: Initialization
  ################################################################################################
  
  # Function: initialize
  #   Constructs a FacebookDesktopSession.  Also calls the API to grab an auth_token.
  #
  # Parameters:
  #   api_key                   - your API key
  #   api_secret                - your API secret
  #   options.suppress_errors   - boolean, set to true if you don't want errors to be thrown (defaults to false)
  def initialize(api_key, api_secret, suppress_errors = false)
    super(api_key, api_secret, suppress_errors)
    @desktop_auth_token = get_auth_token
  end
  
  ################################################################################################
  ################################################################################################
  # :section: URL Accessors
  ################################################################################################
  
  # Function: get_login_url
  #   Gets the authentication URL
  #
  # Parameters:
  #   options.next          - the page to redirect to after login
  #   options.popup         - boolean, whether or not to use the popup style (defaults to true)
  #   options.skipcookie    - boolean, whether to force new Facebook login (defaults to false)
  #   options.hidecheckbox  - boolean, whether to show the "infinite session" option checkbox (defaults to false)
  def get_login_url(options={})
    # options
    path_next = options[:next] ||= nil
    popup = (options[:popup] == nil) ? true : false
    skipcookie = (options[:skipcookie] == nil) ? false : true
    hidecheckbox = (options[:hidecheckbox] == nil) ? false : true
    
    # get some extra portions of the URL
    optionalNext = (path_next == nil) ? "" : "&next=#{CGI.escape(path_next.to_s)}"
    optionalPopup = (popup == true) ? "&popup=true" : ""
    optionalSkipCookie = (skipcookie == true) ? "&skipcookie=true" : ""
    optionalHideCheckbox = (hidecheckbox == true) ? "&hide_checkbox=true" : ""
    
    # build and return URL
    return "http://#{WWW_SERVER_BASE_URL}#{WWW_PATH_LOGIN}?v=1.0&api_key=#{@api_key}&auth_token=#{@desktop_auth_token}#{optionalPopup}#{optionalNext}#{optionalSkipCookie}#{optionalHideCheckbox}"
  end
  
  ################################################################################################
  ################################################################################################
  # :section: Session Activation
  ################################################################################################
  
  # Function: activate
  #   Use the internal auth_token to activate
  def activate
    result = call_method("auth.getSession", {:auth_token => @desktop_auth_token}, true)
    if result != nil
      @session_user_id = result.at("uid").inner_html
      @session_key = result.at("session_key").inner_html
      @session_secret = result.at("secret").inner_html
    end
  end
  
  # Function: activate_with_previous_session
  #   Sets the session key and secret directly (for example, if you have an infinite session key)
  # 
  # Parameters:
  #   key    - the session key to use
  #   secret - the session secret to use
  def activate_with_previous_session(key, secret)
    # set the session key and secret
    @session_key = key
    @session_secret = secret
    
    # determine the current user's id
    result = call_method("users.getLoggedInUser")
    @session_user_id = result.at("users_getLoggedInUser_response").inner_html
  end
  
  protected
  
  # Function: auth_createToken
  #   Returns a string auth_token
  def get_auth_token # :nodoc:
    result = call_method("auth.createToken", {})
    result = result.at("auth_createToken_response").inner_html.to_s ||= result.at("auth_createToken_response").inner_html.to_s
    return result
  end
  
  
  ################################################################################################
  ################################################################################################
  # :section: Template Methods
  ################################################################################################
    
  # Function: is_activated?
  #   Returns true when we have activated ourselves somehow
  def is_activated?
    return (@session_key != nil and @session_secret != nil)
  end
  
  # Function: get_secret
  #   Used by super::signature to generate a signature.
  #   Desktop sessions should use their session_secret rather than the api_secret
  #   for any calls other than the call to createToken and getSession
  def get_secret(params) # :nodoc:
    
    if ( params[:method] != "facebook.auth.getSession" and params[:method] != "facebook.auth.createToken")
      return @session_secret
    else
      return @api_secret
    end
    
  end
  
end



end
    
