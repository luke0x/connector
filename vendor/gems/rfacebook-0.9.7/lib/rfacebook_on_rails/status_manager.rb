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

module RFacebook
  module Rails
    
    class StatusManager
      
      def initialize(checks)
        @checks = checks
      end
      
      def all_valid?
        allValid = true
        @checks.each do |check|
          allValid = false if !check.valid?
        end
        return allValid
      end
      
      def each_status_check
        @checks.each do |check|
          yield(check)
        end
      end
      
    end
    
    ###########################################
    class StatusCheck
      def valid?
        return @valid
      end
      def message
        if valid?
          return valid_message
        else
          return invalid_message
        end
      end
    end
    
    ###########################################
    class SessionStatusCheck < StatusCheck
      def initialize(controller)
        @controller = controller
        @valid = false
        begin
          if controller.fbsession.is_valid?
            @valid = true
          end
        rescue
        end
      end
      
      def title
        "fbsession"
      end
      
      def valid_message
        "session is ready to make API calls"
      end
      
      def invalid_message
        "session is invalid, you will not be able to make API calls (possibly due to a bad API key or secret)"
      end
      
    end
    ###########################################
    class FacebookParamsStatusCheck < StatusCheck
      def initialize(controller)
        @controller = controller
        @valid = false
        begin
          if @controller.fbparams.size > 0
            @valid = true
          end
        rescue
        end
      end
      
      def title
        "fbparams"
      end
      
      def valid_message
        @controller.fbparams
      end
      
      def invalid_message
        "fbparams is not populated since we weren't able to validate the signature (possibly due to a bad API key or secret)"
      end
      
    end
    ###########################################
    class InCanvasStatusCheck < StatusCheck
      def initialize(controller)
        @controller = controller
        @valid = true
      end
      
      def title
        "in_facebook_canvas?"
      end
      
      def valid_message
        @controller.in_facebook_canvas? ? "yes" : "no"
      end
      
      def invalid_message
        "this should never be invalid"
      end
      
    end
    ###########################################
    class InFrameStatusCheck < StatusCheck
      def initialize(controller)
        @controller = controller
        @valid = true
      end
      
      def title
        "in_facebook_frame?"
      end
      
      def valid_message
        @controller.in_facebook_frame? ? "yes" : "no"
      end
      
      def invalid_message
        "this should never be invalid"
      end
      
    end
    ###########################################
    class CanvasPathStatusCheck < StatusCheck
      def initialize(controller)
        @controller = controller
        @valid = false
        begin
          @valid = @controller.facebook_canvas_path.size > 0
        rescue
        end
      end
      
      def title
        "facebook_canvas_path"
      end
      
      def valid_message
        @controller.facebook_canvas_path
      end
      
      def invalid_message
        begin
          FACEBOOK[:test]
          return "you need to define <strong>canvas_path</strong> in facebook.yml"
        rescue
          return "you need to define s<strong>facebook_canvas_path</strong> in your controller"
        end
      end
      
    end
    ###########################################
    class CallbackPathStatusCheck < StatusCheck
      def initialize(controller)
        @controller = controller
        @valid = false
        begin
          @valid = @controller.facebook_callback_path.size > 0
        rescue
        end
      end
      
      def title
        "facebook_callback_path"
      end
      
      def valid_message
        @controller.facebook_callback_path
      end
      
      def invalid_message
        begin
          FACEBOOK[:test]
          return "you need to define <strong>callback_path</strong> in facebook.yml"
        rescue
          return "you need to define s<strong>facebook_callback_path</strong> in your controller"
        end
      end
      
    end
    ###########################################
    class APIKeyStatusCheck < StatusCheck
      def initialize(controller)
        @controller = controller
        @valid = false
        begin
          if @controller.facebook_api_key.size > 0
            @valid = true
          end
        rescue
        end
      end
      
      def title
        "facebook_api_key"
      end
      
      def valid_message
        @controller.facebook_api_key
      end
      
      def invalid_message
        begin
          FACEBOOK[:test]
          return "you need to put your API <strong>key</strong> in facebook.yml"
        rescue
          return "you need to define s<strong>facebook_api_key</strong> in your controller"
        end
      end
      
    end
    ###########################################
    class APISecretStatusCheck < StatusCheck
      def initialize(controller)
        @controller = controller
        @valid = false
        begin
          if @controller.facebook_api_secret.size > 0
            @valid = true
          end
        rescue
        end
      end
      
      def title
        "facebook_api_secret"
      end
      
      def valid_message
        @controller.facebook_api_secret
      end
      
      def invalid_message
        begin
          FACEBOOK[:test]
          return "you need to put your API <strong>secret</strong> in facebook.yml"
        rescue
          return "you need to define s<strong>facebook_api_secret</strong> in your controller"
        end
      end
      
    end
    ###########################################
    class FinishFacebookLoginStatusCheck < StatusCheck
      def initialize(controller)
        @controller = controller
        @valid = false
        begin
          @controller.finish_facebook_login
          @valid = true
        rescue
        end
      end
      
      def title
        "finish_facebook_login"
      end
      
      def valid_message
        "finisher method is defined (this is only for external web apps)"
      end
      
      def invalid_message
        "you need to define <strong>finish_facebook_login</strong> in your controller (this is only for external web apps)"
      end
      
    end

    
  end
end