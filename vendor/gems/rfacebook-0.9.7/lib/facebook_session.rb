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

#
# Some code was inspired by techniques used in Alpha Chen's old client.
#

require "digest/md5"
require "net/https"
require "cgi"
require "facepricot"

module RFacebook

API_SERVER_BASE_URL       = "api.facebook.com"
API_PATH_REST             = "/restserver.php"

WWW_SERVER_BASE_URL       = "www.facebook.com"
WWW_PATH_LOGIN            = "/login.php"
WWW_PATH_ADD              = "/add.php"
WWW_PATH_INSTALL          = "/install.php"

class FacebookSession
  
  ################################################################################################
  ################################################################################################
  # :section: Errors
  ################################################################################################
    
  class RemoteStandardError < StandardError; end
  class ExpiredSessionStandardError < StandardError; end
  class NotActivatedStandardError < StandardError; end
    
  ################################################################################################
  ################################################################################################
  # :section: Properties
  ################################################################################################
  
  # Property: session_user_id
  #   The user id of the user associated with this sesssion.
  attr_reader :session_user_id
  
  # Property: session_key
  #   The key for this session. You will need to save this for infinite sessions.
  attr_reader :session_key
  
  # Property: session_expires
  #   The expiration time of this session, as given from Facebook API login.
  attr_reader :session_expires
  
  # Property: last_error_message
  #   Contains a string message of the last error received from Facebook.
  attr_reader :last_error_message
  
  # Property: last_error_code
  #   Contains an integer code of the last error received from Facebook.
  attr_reader :last_error_code
  
  # Property: suppress_errors
  #   By default, RFacebook will throw exceptions when errors occur.
  #   You can set suppress_errors=true to stop these exceptions
  #   from being thrown.
  attr_accessor :suppress_errors
  
  # Property: logger
  #   Can be set to any valid logger (for example, RAIL_DEFAULT_LOGGER)
  attr_accessor :logger
  
  # Function: is_activated?
  #   Returns true when the session has been activated in some way
  #   THIS IS AN ABSTRACT METHOD (the value is determined differently for Web and Desktop sessions)
  def is_activated?
    raise StandardError
  end
  
  # Function: is_expired?
  #   Returns true when the session has expired
  def is_expired?
    # TODO: this should look at the @session_expires as well
    return (@session_expired == true)
  end
  
  # Function: is_valid?
  #   Returns true when the session is definitely prepared to make API calls
  def is_valid?
    return (is_activated? and !is_expired?)
  end
  
  # Function: is_ready?
  #   alias for is_valid?
  def is_ready?
    return is_valid?
  end
  
  ################################################################################################
  ################################################################################################
  # :section: Initialization
  ################################################################################################
  
  # Function: initialize
  #   Constructs a FacebookSession
  #
  # Parameters:
  #   api_key           - your API key
  #   api_secret        - your API secret
  #   suppress_errors   - boolean, set to true if you don't want exceptions to be thrown (defaults to false)
  #
  def initialize(api_key, api_secret, suppress_errors = false)
    
    # required parameters
    @api_key = api_key
    @api_secret = api_secret
        
    # optional parameters
    @suppress_errors = suppress_errors
    
    # initialize internal state
    @last_error_message = nil
    @last_error_code = nil
    @session_expired = false
    
    # cache object for API calls
    @callcache = {}
        
  end
      
  ################################################################################################
  ################################################################################################
  # :section: API Calls
  ################################################################################################
  protected
    
  # Function: method_missing
  #   This allows *any* Facebook method to be called, using the Ruby
  #   mechanism for responding to unimplemented methods.  Basically,
  #   this converts a call to "auth_getSession" to "auth.getSession"
  #   and does the proper API call using the parameter hash given.
  #
  #   This allows you to call an API method such as facebook.users.getInfo
  #   by calling "fbsession.users_getInfo"
  #
  def method_missing(methodSymbol, *params)
    tokens = methodSymbol.to_s.split("_")
    if tokens[0] == "cached"
      tokens.shift
      return cached_call_method(tokens.join("."), params.first)
    else
      return call_method(tokens.join("."), params.first)
    end
  end

  
  # Function: call_method
  #   Sets up the necessary parameters to make the POST request to the server
  #
  # Parameters:
  #   method              - i.e. "users.getInfo"
  #   params              - hash of key,value pairs for the parameters to this method
  #   use_ssl             - set to true if the call will be made over SSL
  def call_method(method, params={}, use_ssl=false) # :nodoc:

    log_debug "** RFACEBOOK(GEM) - RFacebook::FacebookSession\#call_method - #{method}(#{params.inspect}) - making remote call"

    # ensure that this object has been activated somehow
    if (!method.include?("auth") and !is_activated?)
      raise NotActivatedStandardError, "You must activate the session before using it."
    end
    
    # set up params hash
    if (!params)
      params = {}
    end
    params = params.dup
    
    # params[:format] ||= @response_format
    params[:method] = "facebook.#{method}"
    params[:api_key] = @api_key
    params[:v] = "1.0"
    
    if (method != "auth.getSession" and method != "auth.createToken")
      params[:session_key] = session_key
      params[:call_id] = Time.now.to_f.to_s
    end
    
    # convert arrays to comma-separated lists
    params.each{|k,v| params[k] = v.join(",") if v.is_a?(Array)}
    
    # set up the param_signature value in the params
    params[:sig] = param_signature(params)
    
    # make the remote call and contain the results in a Facepricot XML object
    rawxml = post_request(params, use_ssl)
    xml = Facepricot.new(rawxml)

    # error checking    
    if xml.at("error_response")
      
      log_debug "** RFACEBOOK(GEM) - RFacebook::FacebookSession\#call_method - #{method}(#{params.inspect}) - remote call failed"
      
      code = xml.at("error_code").inner_html.to_i
      msg = xml.at("error_msg").inner_html
      @last_error_message = "ERROR #{code}: #{msg} (#{method.inspect}, #{params.inspect})"
      @last_error_code = code
      
      # check to see if this error was an expired session error
      if code == 102
        @session_expired = true
        raise ExpiredSessionStandardError, @last_error_message unless @suppress_errors == true
      end
      
      # TODO: check for method not existing error (what code is it?)
      #       and convert it to a Ruby "NoMethodError"
      
      # otherwise, just throw a generic expired session
      raise RemoteStandardError, @last_error_message unless @suppress_errors == true
      
      return nil
    end
    
    return xml
  end
  
  # Function: post_request
  #   Posts a request to the remote Facebook API servers, and returns the
  #   raw body of the result
  #
  # Parameters:
  #   params  - a Hash of the post parameters to send to the REST API
  #   use_ssl - defaults to false, set to true if you want to use SSL for the POST
  def post_request(params, use_ssl=false)
    
    # get a server handle
    port = (use_ssl == true) ? 443 : 80
    http_server = Net::HTTP.new(API_SERVER_BASE_URL, port)
    http_server.use_ssl = use_ssl
    
    # build a request
    http_request = Net::HTTP::Post.new(API_PATH_REST)
    http_request.form_data = params
    
    # get the response XML
    return http_server.start{|http| http.request(http_request)}.body
  end
  
  # Function: cached_call_method
  #   Does the same thing as call_method, except that the response is cached for
  #   the lifetime of the FacebookSession.
  #
  # Parameters:
  #   method              - i.e. "users.getInfo"
  #   params              - hash of key,value pairs for the parameters to this method
  #   use_ssl             - set to true if the call will be made over SSL
  def cached_call_method(method,params={},use_ssl=false) # :nodoc:
    key = cache_key_for(method,params)
    log_debug "** RFACEBOOK(GEM) - RFacebook::FacebookSession\#cached_call_method - #{method}(#{params.inspect}) - attempting to hit cache"
    return @callcache[key] ||= call_method(method,params,use_ssl)
  end
  
  # Function: cache_key_for
  #   Key to use for cached method calls.
  #
  # Parameters:
  #   method      - the API method being cached
  #   params      - a Hash of the parameters being sent to the API
  #
  def cache_key_for(method,params) # :nodoc:
    pairs = []
    params.each do |k,v|
      if v.is_a?(Array)
        v = v.join(",")
      end
      pairs << "#{k}=#{v}"
    end
    return "#{method}(#{pairs.sort.join("...")})".to_sym
  end
  
  ################################################################################################
  ################################################################################################
  # :section: Signature Generation
  ################################################################################################

  # Function: get_secret
  #   Returns the proper secret to sign a set of parameters with.
  #   A WebSession will always use the api_secret, but a DesktopSession
  #   sometimes needs to use a session_secret.
  #
  #   THIS IS AN ABSTRACT METHOD
  #
  # Parameters:
  #   params    - a Hash containing the parameters to sign
  #
  def get_secret(params) # :nodoc:
    raise StandardError
  end
    
  # Function: param_signature
  #   Generates a param_signature for a call to the API, per the spec on Facebook
  #   see: <http://developers.facebook.com/documentation.php?v=1.0&doc=auth>
  #
  # Parameters:
  #   params    - a Hash containing the parameters to sign
  #
  def param_signature(params)   # :nodoc:  
    return generate_signature(params, get_secret(params));
  end
  
  # Function: generate_signature
  #   Generates a Facebook signature.  Used for generating API calls, as well
  #   as for checking the signature from a Canvas page
  #
  # Parameters:
  #   hash    - a Hash containing the parameters to sign
  #   secret  - the API or session secret to use to sign the parameters
  #
  def generate_signature(hash, secret) # :nodoc:
    args = []
    hash.each do |k,v|
      args << "#{k}=#{v}"
    end
    sortedArray = args.sort
    requestStr = sortedArray.join("")
    return Digest::MD5.hexdigest("#{requestStr}#{secret}")
  end
  
  ################################################################################################
  ################################################################################################
  # :section: Marshalling Serialization Overrides
  ################################################################################################
  public
    
  def _dump(depth)
    instanceVarHash = {}
    self.instance_variables.each { |k| instanceVarHash[k] = self.instance_variable_get(k) }
    # the logger must be removed before serializing
    return Marshal.dump(instanceVarHash.delete_if{|k,v| k == "@logger"})
  end
  
  def self._load(dumpedStr)
    instance = self.new(nil,nil)
    dumped = Marshal.load(dumpedStr)
    dumped.each do |k,v|
      instance.instance_variable_set(k,v)
    end
    return instance
  end
  
  ################################################################################################
  ################################################################################################
  # :section: Logging
  ################################################################################################
  private
  
  def log_debug(message) # :nodoc:
    @logger.debug(message) if @logger
  end
  
  def log_info(message) # :nodoc:
    @logger.info(message) if @logger
  end
  
  ################################################################################################
  ################################################################################################
  # :section: Deprecated Methods
  ################################################################################################
  public
  
  # DEPRECATED in favor of session_user_id
  def session_uid # :nodoc:
    log_debug "** RFACEBOOK(GEM) - DEPRECATION NOTICE - fbsession.session_uid is deprecated in favor of fbsession.session_user_id"
    return self.session_user_id
  end
  
  # DEPRECATED in favor of last_error_message
  def last_error # :nodoc:
    log_debug "** RFACEBOOK(GEM) - DEPRECATION NOTICE - fbsession.last_error is deprecated in favor of fbsession.last_error_message"
    return self.last_error_message
  end
  
  # DEPRECATED in favor of suppress_errors
  def suppress_exceptions # :nodoc:
    log_debug "** RFACEBOOK(GEM) - DEPRECATION NOTICE - fbsession.suppress_exceptions is deprecated in favor of fbsession.suppress_errors"
    return self.suppress_errors
  end
  
  # DEPRECATED in favor of suppress_errors
  def suppress_exceptions=(value) # :nodoc:
    log_debug "** RFACEBOOK(GEM) - DEPRECATION NOTICE - fbsession.suppress_exceptions is deprecated in favor of fbsession.suppress_errors"
    self.suppress_errors = value
  end
  
  # DEPRECATED in favor of is_expired?
  def session_expired?
    log_debug "** RFACEBOOK(GEM) - DEPRECATION NOTICE - fbsession.session_expired? is deprecated in favor of fbsession.is_expired?"
    return self.is_expired?
  end


end

end
