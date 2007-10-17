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

require "facebook_web_session"
require "rfacebook_on_rails/status_manager"

module RFacebook
  module Rails
    module ControllerExtensions
      
      # :section: StandardErrors
    
      class APIKeyNeededStandardError < StandardError; end # :nodoc:
      class APISecretNeededStandardError < StandardError; end # :nodoc:
      class APICanvasPathNeededStandardError < StandardError; end # :nodoc:
      class APICallbackNeededStandardError < StandardError; end # :nodoc:
      class APIFinisherNeededStandardError < StandardError; end # :nodoc:
    
      # :section: Template Methods (must be implemented by concrete subclass)
    
      def facebook_api_key
        raise APIKeyNeededStandardError, "RFACEBOOK ERROR: when using the RFacebook on Rails plugin, please be sure that you have a facebook.yml file with 'key' defined"
      end
    
      def facebook_api_secret
        raise APISecretNeededStandardError, "RFACEBOOK ERROR: when using the RFacebook on Rails plugin, please be sure that you have a facebook.yml file with 'secret' defined"
      end
      
      def facebook_canvas_path
        raise APICanvasPathNeededStandardError, "RFACEBOOK ERROR: when using the RFacebook on Rails plugin, please be sure that you have a facebook.yml file with 'canvas_path' defined"
      end
      
      def facebook_callback_path
        raise APICallbackNeededStandardError, "RFACEBOOK ERROR: when using the RFacebook on Rails plugin, please be sure that you have a facebook.yml file with 'callback_path' defined"
      end
    
      def finish_facebook_login
        raise APIFinisherNeededStandardError, "RFACEBOOK ERROR: in an external Facebook application, you should define finish_facebook_login in your controller (often this is used to redirect to a 'login success' page, but it can also simply do nothing)"
      end
    
    
    
      # :section: Special Variables
    
      # Function: fbparams
      #   Accessor for all params beginning with "fb_sig_"
      #
      # Returns:
      #   A Hash of those parameters, with the fb_sig_ stripped from the keys
      def fbparams
      
        # try to get fbparams from the params hash
        if (!@fbparams || @fbparams.length <= 0)
          dup_params = (self.params || {}).dup
          @fbparams = rfacebook_session_holder.get_fb_sig_params(dup_params)
        end
      
        # else, try to get fbparams from the cookies hash
        if (!@fbparams || @fbparams.length <= 0)
          dup_cookies = (self.cookies || {}).dup
          @fbparams = rfacebook_session_holder.get_fb_sig_params(dup_cookies)
        end
        
        # finally, if we are an iframe app we may have saved the fbparams
        # to the session for safekeeping
        if (!@fbparams || @fbparams.length <= 0)
          @fbparams = session[:rfacebook_session_iframe_fbparams] || {}
        end
              
        return @fbparams
      
      end
      
      # Function: fbsession
      #   Accessor for a FacebookWebSession that has been activated, either in the Canvas
      #   (via fb_sig parameters) or in an external app (via an auth_token).
      #
      # Returns:
      #   A FacebookWebSession.  You may want to check is_valid? before using it.
      def fbsession
        
        # do a check to ensure that we nil out the rfacebook_session in case there is a new user visiting
        if session[:rfacebook_session] and fbparams["session_key"] and session[:rfacebook_session].session_key != fbparams["session_key"]
          session[:rfacebook_session] = nil
        end
        
        # if we are in the canvas, iframe, or mock ajax, we should be able to activate the session here
        if (!rfacebook_session_holder.is_valid? and (in_facebook_canvas? or in_facebook_frame? or in_mock_ajax?))
                            
          # then try to activate it somehow (or retrieve from previous state)
          # these might be nil
          facebookUid = fbparams["user"]
          facebookSessionKey = fbparams["session_key"]
          expirationTime = fbparams["expires"]
                
          if (facebookUid and facebookSessionKey and expirationTime)
            # we have the user id and key from the fb_sig_ params, activate the session
            rfacebook_session_holder.activate_with_previous_session(facebookSessionKey, facebookUid, expirationTime)
            RAILS_DEFAULT_LOGGER.debug "** RFACEBOOK INFO: Activated session from inside the canvas (user=#{facebookUid}, session_key=#{facebookSessionKey}, expires=#{expirationTime})"
          else
            RAILS_DEFAULT_LOGGER.debug "** RFACEBOOK WARNING: Tried to get a valid Facebook session from POST params, but failed"
          end
          
        end
        
        # if we still don't have a session, check the Rails session
        # (used for external and iframe apps when fb_sig POST params weren't present)
        if (!rfacebook_session_holder.is_valid? and session[:rfacebook_session] and session[:rfacebook_session].is_valid?)
        
          # grab saved Facebook session from Rails session
          RAILS_DEFAULT_LOGGER.debug "** RFACEBOOK INFO: grabbing Facebook session from Rails session"
          @rfacebook_session_holder = session[:rfacebook_session]
          @rfacebook_session_holder.logger = RAILS_DEFAULT_LOGGER
                      
        end
        
        # if all went well, we should definitely have a valid Facebook session object
        return rfacebook_session_holder
      
      end
    
      # :section: Helpful Methods
    
      # DEPRECATED
      def facebook_redirect_to(url) # :nodoc:
        RAILS_DEFAULT_LOGGER.info "** RFACEBOOK DEPRECATION NOTICE: facebook_redirect_to is deprecated in RFacebook. Instead, you can use redirect_to like any Rails app."
        if in_facebook_canvas?
          render :text => "<fb:redirect url=\"#{url}\" />"     
        elsif url =~ /^https?:\/\/([^\/]*\.)?facebook\.com(:\d+)?/i
          render :text => "<script type=\"text/javascript\">\ntop.location.href = \"#{url}\";\n</script>";
        else
          redirect_to url
        end
      end
    
      def in_facebook_canvas?
        in_canvas = params["fb_sig_in_canvas"] || fbparams["in_canvas"]
        return (in_canvas == "1" || in_canvas == true)
      end
        
      def in_facebook_frame?
        in_iframe = params["fb_sig_in_iframe"] || fbparams["in_iframe"]
        return (in_iframe == "1" || in_iframe == true)
      end
      
      def in_mock_ajax?
        is_mockajax = params["fb_sig_is_mockajax"]
        return (is_mockajax == "1" || is_mockajax == true || params["fb_mockajax_url"] != nil)
      end
      
      def in_ajax?
        is_ajax = params["fb_sig_is_ajax"]
        return (is_ajax == "1" || is_ajax == true)
      end
      
      def in_external_app?
        # FIXME: once you click away in an iframe app, you are considered to be an external app
        # TODO: read up on the hacks for avoiding nested iframes
        return (params["fb_sig"] == nil and !in_facebook_frame?)
      end
      
      def added_facebook_application?
        addedApp = params["fb_sig_added"] || fbparams["added"]
        return (addedApp == "1" || addedApp == true)
      end
      
      def facebook_platform_signature_verified?
        return (fbparams and fbparams.size > 0)
      end
      
      # TODO: define something along the lines of is_logged_in_to_facebook? that returns fbsession.is_ready? perhaps
      
      ################################################################################################
      ################################################################################################
      # :section: before_filters
      ################################################################################################
          
      def handle_facebook_login
                        
        # we only do this when we don't have the fb_sig to give us a session
        # in these cases, we always check to see if we got an auth_token
        # from redirecting to login to facebook
        if (!facebook_platform_signature_verified? and params["auth_token"])
          
          # activate with the auth token
          RAILS_DEFAULT_LOGGER.debug "** RFACEBOOK INFO: attempting to create a new Facebook session from auth_token"
          staleToken = false
          begin
            
            # try to use the auth_token
            rfacebook_session_holder.activate_with_token(params["auth_token"])
            
          rescue StandardError => e
            RAILS_DEFAULT_LOGGER.debug "** RFACEBOOK INFO: Tried to use a stale auth_token"
            staleToken = true
          end
            
          # template method call upon success
          if (rfacebook_session_holder.is_valid? and !staleToken)
            RAILS_DEFAULT_LOGGER.debug "** RFACEBOOK INFO: Login was successful, calling finish_facebook_login"
            if in_external_app?
              finish_facebook_login
            end
          end
      
          # warning logs
          if !rfacebook_session_holder.is_valid?
            RAILS_DEFAULT_LOGGER.info "** RFACEBOOK WARNING: Facebook session could not be activated with auth_token"
          end
        
        end
        
        return true
      end
    
      def require_facebook_login
            
        # now finish it off depending on whether we are in canvas, iframe, or external app
        if !performed?
                
          # try to get the session
          sess = fbsession
      
          # handle invalid sessions by forcing the user to log in      
          if !sess.is_valid?
          
            RAILS_DEFAULT_LOGGER.debug "** RFACEBOOK INFO: Session is not valid"
          
            if in_external_app?
              
              RAILS_DEFAULT_LOGGER.debug "** RFACEBOOK INFO: Redirecting to login for external app"
              redirect_to sess.get_login_url
              return false
              
            elsif (!fbparams or fbparams.size == 0)
              
              RAILS_DEFAULT_LOGGER.debug "** RFACEBOOK WARNING: Failed to activate due to a bad API key or API secret"
              render :text => facebook_debug_panel
              return false
              
            else
              
              RAILS_DEFAULT_LOGGER.debug "** RFACEBOOK INFO: Redirecting to login for canvas app"
              redirect_to sess.get_login_url(:canvas=>true)
              return false
              
            end
          end
        end
        
        return true
      end
    
      def require_facebook_install
        if (in_facebook_canvas? or in_facebook_frame?)
          if (!fbsession.is_valid? or !added_facebook_application?)
            redirect_to fbsession.get_install_url
            return false
          end
        else
          RAILS_DEFAULT_LOGGER.info "** RFACEBOOK WARNING: require_facebook_install is not intended for external applications, using require_facebook_login instead"
          return require_facebook_login
        end
        return true
      end
      
      # TODO: check this out
      # def require_facebook_install                              
      #   if in_facebook_frame? and not added_facebook_application?
      #     render :text => %Q(<script language="javascript">top.location.href="#{fbsession.get_install_url}&next=#{request.path.gsub(/#{facebook_callback_path}/, "")}"</script>)
      #   end
      # end
      
      ################################################################################################
      ################################################################################################
      # :section: Facebook Debug Panel
      ################################################################################################
      
      def render_with_facebook_debug_panel(options={})
        begin
          renderedOutput = render_to_string(options)
        rescue Exception => e
          renderedOutput = facebook_canvas_backtrace(e)
        end
        render_text "#{facebook_debug_panel}#{renderedOutput}"
      end
      
      def facebook_debug_panel(options={})
        template = File.read(File.dirname(__FILE__) + "/templates/debug_panel.rhtml")
        return ERB.new(template).result(Proc.new{})
      end
      
      # TODO: implement this in version 1.0
      # def rescue_action(exception)
      #   # TODO: for security, we only do this in development in the canvas
      #   if (in_facebook_canvas? and RAILS_ENV == "development")
      #     render_text "#{facebook_debug_panel}#{facebook_canvas_backtrace(exception)}"
      #   else
      #     # otherwise, do the default
      #     super
      #   end
      # end
      
      def facebook_canvas_backtrace(exception)
        
        # TODO: potentially integrate features from Evan Weaver's facebook_exceptions
        rfacebookBacktraceLines = []
        exception.backtrace.each do |line|
          
          # escape HTML
          cleanLine = line.gsub(RAILS_ROOT, "").gsub("<", "&lt;").gsub(">", "&gt;")
          
          # split up these lines by carriage return
          pieces = cleanLine.split("\n")
          if (pieces and pieces.size> 0)
            pieces.each do |piece|
              if matches = /.*[\/\\]+((.*)\:([0-9]+)\:\s*in\s*\`(.*)\')/.match(piece)
                # for each parsed line, add to the array for later rendering in the template
                rfacebookBacktraceLines << {
                  :filename => matches[2],
                  :line => matches[3],
                  :method => matches[4],
                  :rawsummary => piece,
                }
              end
            end
          end
        end
        
        # render to the ERB template
        template = File.read(File.dirname(__FILE__) + "/templates/exception_backtrace.rhtml")
        return ERB.new(template).result(Proc.new{})

      end
      
      def facebook_status_manager # :nodoc:
        checks = [
          SessionStatusCheck.new(self),
          (FacebookParamsStatusCheck.new(self) unless (!in_facebook_canvas? and !in_facebook_frame?)),
          InCanvasStatusCheck.new(self),
          InFrameStatusCheck.new(self),
          (CanvasPathStatusCheck.new(self) unless (!in_facebook_canvas? or !in_facebook_frame?)),
          (CallbackPathStatusCheck.new(self) unless (!in_facebook_canvas? or !in_facebook_frame?)),
          (FinishFacebookLoginStatusCheck.new(self) unless (in_facebook_canvas? or in_facebook_frame?)),
          APIKeyStatusCheck.new(self),
          APISecretStatusCheck.new(self)
          ].compact
        return StatusManager.new(checks)
      end
      
      ################################################################################################
      ################################################################################################
      # :section: RFacebook Private Methods
      ################################################################################################
      
      def rfacebook_session_holder # :nodoc:
        
        if (@rfacebook_session_holder == nil)
          @rfacebook_session_holder = FacebookWebSession.new(facebook_api_key, facebook_api_secret)
          @rfacebook_session_holder.logger = RAILS_DEFAULT_LOGGER
        end
        
        return @rfacebook_session_holder
        
      end
            
      def rfacebook_persist_session_to_rails # :nodoc:
        if (!in_facebook_canvas? and rfacebook_session_holder.is_valid?)
          RAILS_DEFAULT_LOGGER.debug "** RFACEBOOK INFO: persisting Facebook session information into Rails session"
          session[:rfacebook_session] = @rfacebook_session_holder.dup # TODO: do we need dup here anymore?
          if in_facebook_frame?
            # we need iframe apps to remember they are iframe apps
            session[:rfacebook_session_iframe_fbparams] = fbparams
          end
        end
      end
      
      
      ################################################################################################
      ################################################################################################
      # :section: URL Management
      ################################################################################################
      
      def url_for__RFACEBOOK(options={}, *parameters) # :nodoc:
        
        # fix problems that some Rails installations had with sending nil options
        options ||= {}
                
        # use special URL rewriting when inside the canvas
        # setting the full_callback option to true will override this
        # and force usage of regular Rails rewriting        
        if options.is_a? Hash
          if options[:mock_ajax]
            RAILS_DEFAULT_LOGGER.info "** RFACEBOOK DEPRECATION WARNING: don't use :mock_ajax => true in your link_to anymore.  Instead, use :full_callback => true."
          end
          fullCallback = (options[:full_callback] == true) ? true : false
          options.delete(:full_callback)
        end
          
        if ((in_facebook_canvas? or in_mock_ajax? or in_ajax?) and !fullCallback) #TODO: do something separate for in_facebook_frame?
          
          if options.is_a? Hash
            options[:only_path] = true if options[:only_path].nil?
          end
          
          # try to get a regular URL
          path = url_for__ALIASED(options, *parameters)
                          
          # replace anything that references the callback with the
          # Facebook canvas equivalent (apps.facebook.com/*)
          if path.starts_with?(self.facebook_callback_path)
            path.sub!(self.facebook_callback_path, self.facebook_canvas_path)
            path = "http://apps.facebook.com#{path}"
          elsif "#{path}/".starts_with?(self.facebook_callback_path)
            path.sub!(self.facebook_callback_path.chop, self.facebook_canvas_path.chop)
            path = "http://apps.facebook.com#{path}"
          elsif (path.starts_with?("http://www.facebook.com") or path.starts_with?("https://www.facebook.com"))
            # be sure that URLs that go to some other Facebook service redirect back to the canvas
            if path.include?("?")
              path = "#{path}&canvas=true"
            else
              path = "#{path}?canvas=true"
            end
          elsif (!path.starts_with?("http://") and !path.starts_with?("https://"))
            # default to a full URL (will link externally)
            RAILS_DEFAULT_LOGGER.debug "** RFACEBOOK INFO: failed to get canvas-friendly URL ("+path+") for ["+options.inspect+"], creating an external URL instead"
            path = "#{request.protocol}#{request.host}:#{request.port}#{path}"
          end
        
        # full callback rewriting
        elsif fullCallback
          options[:only_path] = true
          path = "#{request.protocol}#{request.host}:#{request.port}#{url_for__ALIASED(options, *parameters)}"
        
        # regular Rails rewriting
        else
          path = url_for__ALIASED(options, *parameters)
        end

        return path
      end
      
      def redirect_to__RFACEBOOK(options = {}, *parameters) # :nodoc:
        
        # BEGIN JOYENT MODIFICATION
        redirectUrl = case options
        when %r{^\w+://.*}
          options
        when String
          request.protocol + request.host_with_port + options
        when :back
          request.env["HTTP_REFERER"] || raise(RedirectBackError)
        end
        # END JOYENT MODIFICATION
        
        # canvas redirect
        if in_facebook_canvas?
                  
          RAILS_DEFAULT_LOGGER.debug "** RFACEBOOK INFO: Canvas redirect to #{redirectUrl}"
          render :text => "<fb:redirect url=\"#{redirectUrl}\" />"
        
        # iframe redirect
        elsif redirectUrl.match(/^https?:\/\/([^\/]*\.)?facebook\.com(:\d+)?/i)
          RAILS_DEFAULT_LOGGER.debug "** RFACEBOOK INFO: iframe redirect to #{redirectUrl}"
          render :text => %Q(<script type="text/javascript">\ntop.location.href='#{redirectUrl}';\n</script>)
          
        # otherwise, we only need to do a standard redirect
        else
          RAILS_DEFAULT_LOGGER.debug "** RFACEBOOK INFO: Regular redirect_to"
          redirect_to__ALIASED(options, *parameters)
        end
      end
   
      
      ################################################################################################
      ################################################################################################
      # :section: Extension Helpers
      ################################################################################################
      
      CLASSES_EXTENDED = [] # :nodoc:
            
      def self.included(base) # :nodoc:
        
        # check for a double include
        doubleInclude = false
        CLASSES_EXTENDED.each do |klass|
          if base.allocate.is_a?(klass)
            doubleInclude = true
          end
        end
        
        if doubleInclude
          RAILS_DEFAULT_LOGGER.info "** RFACEBOOK WARNING: detected double-include of RFacebook controller extensions.  Please see instructions for RFacebook on Rails plugin usage (http://rfacebook.rubyforge.org).  You may be including the deprecated RFacebook::RailsControllerExtensions in addition to the plugin."
          
        else
          
          # keep track that we have already extended this class
          CLASSES_EXTENDED << base
          
          # we need to use an eval since we will be overriding ActionController::Base methods
          # and we need to be able to call the originals
          base.class_eval '
            alias_method(:url_for__ALIASED, :url_for)
            alias_method(:url_for, :url_for__RFACEBOOK)      
          
            alias_method(:redirect_to__ALIASED, :redirect_to)
            alias_method(:redirect_to, :redirect_to__RFACEBOOK)
          '
          
          # ensure that every action handles facebook login
          base.before_filter(:handle_facebook_login)
          
          # ensure that we persist the Facebook session into the Rails session (if possible)
          base.after_filter(:rfacebook_persist_session_to_rails)
          
          # fix third party cookies in IE
          base.before_filter{ |c| c.headers['P3P'] = %|CP="NOI DSP COR NID ADMa OPTa OUR NOR"| }
          
        end
      end


    end
  end
end
