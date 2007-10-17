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

require File.expand_path(File.join(File.dirname(__FILE__), '../../../../config/environment.rb'))
require "action_controller/test_process"
require "action_controller/integration"

# helpers for all RFacebook unit tests
class Test::Unit::TestCase
  
  def assert_rfacebook_overrides_method(object, methodSymbol)
    
    # by convention, RFacebook postfixes its overrides with __RFACEBOOK
    # and postfixes the original methods with __ALIASED
    rfacebookMethodSymbol = "#{methodSymbol}__RFACEBOOK".to_sym
    aliasedMethodSymbol = "#{methodSymbol}__ALIASED".to_sym
    
    # string description of this object
    objectDescription = object.is_a?(Class) ? object.to_s : object.class.to_s
    
    # ensure that the original method is still available
    assert object.respond_to?(aliasedMethodSymbol, true), "Could not find original #{objectDescription}::#{methodSymbol}"
    
    # ensure that the object has the RFacebook override
    assert object.respond_to?(rfacebookMethodSymbol, true), "Could not find RFacebook override of #{objectDescription}::#{methodSymbol}"
    
    # ensure that the override is actually overriding the given method
    assert object.method(methodSymbol) == object.method(rfacebookMethodSymbol), "#{objectDescription}::#{methodSymbol} does not appear to be overridden by RFacebook"
    
  end
  
end

# dummy controller used in many test cases
class DummyController < ActionController::Base
  
  before_filter :require_facebook_login, :only => [:index]
  
  # actions
  def index
    render :text => "viewing index"
  end
    
  def nofilter
    render :text => "no filter needed"
  end
  
  def shouldbeinstalled
    if require_facebook_install
      render :text => "app is installed"
    end
  end
  
  def doredirect
    redirect_to params[:redirect_url]
  end
  
  def render_foobar_action_on_callback
    render :text => url_for("#{facebook_callback_path}foobar")
  end
  
  
  # utility methods
  
  def rescue_action(e) 
    raise e 
  end
  
  
  def stub_fbparams(overriddenOptions={})
    self.stubs(:fbparams).returns({
      "session_key" => "12345",
      "user" => "9876",
      "expires" => Time.now.to_i*2, # timeout long in the future
      "time" => Time.now.to_i*2, # timeout long in the future
    }.merge(overriddenOptions))
  end
    
  def simulate_inside_canvas(moreParams={})
    self.stub_fbparams({"in_canvas"=>true})
    @extra_params = {"fb_sig_in_canvas"=>true}.merge(moreParams)
  end
  
  def params
    if @extra_params
      super.merge(@extra_params)
    else
      super
    end
  end
  
  # for external apps
  def finish_facebook_login
    render :text => "finished facebook login"
  end
  
end

# dummy model used in a few test cases
class DummyModel < ActiveRecord::Base
  acts_as_facebook_user
  
  def facebook_uid
    "dummyuid"
  end
  
  def facebook_session_key
    "dummysessionkey"
  end
end

