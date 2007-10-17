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

require File.dirname(__FILE__) + "/test_helper"
require "test/unit"
require "rubygems"
require "mocha"

class InitializationTest < Test::Unit::TestCase
  
  def setup
    @controller = DummyController.new
  end
  
  def test_yml_loaded_properly
    assert FACEBOOK["key"]
    assert FACEBOOK["secret"]
  end
  
  def test_controller_paths_for_canvas_apps_are_relative
    if FACEBOOK["canvas_path"]
      assert(/^\/(.*)\/$/.match(@controller.facebook_canvas_path), "canvas_path should be relative (check your facebook.yml)")
    end
    
    if FACEBOOK["callback_path"]
      assert(/^\/(.*)\/$/.match(@controller.facebook_callback_path), "callback_path should be relative (check your facebook.yml)")
    end
  end
  
  def test_controller_raises_exceptions_with_missing_yaml_options
    # destroy the configuration to simulate all properties being undefined
    originalFACEBOOK = FACEBOOK.dup
    FACEBOOK.clear
    
    # ensure that the controller extensions raise errors
    assert_raise(RFacebook::Rails::ControllerExtensions::APIKeyNeededStandardError) { @controller.facebook_api_key }
    assert_raise(RFacebook::Rails::ControllerExtensions::APISecretNeededStandardError) { @controller.facebook_api_secret }
    assert_raise(RFacebook::Rails::ControllerExtensions::APICanvasPathNeededStandardError) { @controller.facebook_canvas_path }
    assert_raise(RFacebook::Rails::ControllerExtensions::APICallbackNeededStandardError) { @controller.facebook_callback_path }
    
    # restore the configuration so the rest of the tests run properly
    FACEBOOK.merge!(originalFACEBOOK)
  end
    
end

