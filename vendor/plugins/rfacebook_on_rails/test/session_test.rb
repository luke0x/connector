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

class SessionTest < Test::Unit::TestCase
  
  def setup
    @controller = DummyController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
    
    @cgi_session_placeholder = CGI::Session.allocate
    
    # RFacebook extends a certain subset of Rails session stores,
    # so we must test them each individually
    @sessionStoresToTest = [
      CGI::Session::PStore,
      CGI::Session::ActiveRecordStore,
      CGI::Session::DRbStore,
      CGI::Session::FileStore,
      CGI::Session::MemoryStore
    ]
    
    begin
      # optionally check MemCacheStore (only if memcache-client is installed)
      @sessionStoresToTest << CGI::Session::MemCacheStore
    rescue Exception => e
    end
    
  end
  
  def test_cgi_session_helpers_are_present
    @cgi_session_placeholder.respond_to?(:force_to_be_new!, true)
    @cgi_session_placeholder.respond_to?(:using_facebook_session_id?, true)
  end
  
  def test_cgi_session_overrides_are_present    
    assert_rfacebook_overrides_method(@cgi_session_placeholder, :initialize)
    assert_rfacebook_overrides_method(@cgi_session_placeholder, :new_session)    
  end
  
  def test_session_store_overrides_are_present
    # assert that each of the extended stores has the special RFacebook overrides
    # that enable session storage when inside the canvas
    @sessionStoresToTest.each do |storeKlass|
      assert_rfacebook_overrides_method(storeKlass.allocate, :initialize)
    end
  end
  
  def test_cgi_session_grabs_fb_sig_session_key
    # TODO: implement test
  end
  
  def test_session_store_uses_overridden_init_method_when_in_canvas
    # TODO: implement test
  end
  
  def test_session_store_uses_original_init_method_when_not_in_canvas
    # TODO: implement test
  end
  
end

