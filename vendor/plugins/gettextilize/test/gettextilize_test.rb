#!/usr/bin/env ruby
=begin #(fold)
++
Copyright 2004-2007 Joyent Inc.

Redistribution and/or modification of this code is 
governed by the GPLv2.

Report issues and contribute at http://dev.joyent.com/

$Id$
--
=end #(end)

require 'test/unit'
require 'stringio'

if $0 == __FILE__
  require 'rubygems'
  if Kernel.respond_to? :gem
    gem 'gettext', '>= 1.9.0'
  else
    require_gem 'gettext', '>= 1.9.0'
  end
  require 'gettext'
  require 'gettext/cgi'
end


class GettextilizeTest < Test::Unit::TestCase
  
  include GetText
  extend GetText
  
  def setup
  end
  
  def setup_cgi(str)
    $stdin = StringIO.new(str)
    ENV["REQUEST_URI"] = "http://localhost:3000/"
    cgi = CGI.new
    Locale.cgi = cgi
  end
  
  # Replace this with your real tests.
  def test_gettext_loaded
    assert_kind_of GetText::TextDomainManager, GetText.bindtextdomain('foo')
    assert_equal 'The string', _('The string')
    
  end
  
  def test_gettext
    # This test is an small explanation of how to test gettext in vacuum:

    #1: setup the default locale
    Locale.default = Locale::Object.new("en_GB.UTF-8")
    #2: set a new locale if needed
    GetText.locale = "es"
    #3: bind the textdomain for this file
    GetText.bindtextdomain("datetime", File.join(File.dirname(__FILE__),'../data/locale'))
    assert_equal("Domingo", GetText._("Sunday"))
    assert_equal("Domingo",_('Sunday'))
  end
  
  def test_gettext_cgi
    Locale.default = Locale::Object.new("en_GB.UTF-8")
    #2b: simulate browser request,
    setup_cgi("lang=es_ES")
    #2b: including the proper header
    ENV["HTTP_ACCEPT_LANGUAGE"] = "es,en-us;q=0.7,en;q=0.3"
    #3b: bind the textdomain again
    GetText.bindtextdomain("datetime", File.join(File.dirname(__FILE__),'../data/locale'))
    assert_equal("Domingo", GetText._("Sunday"))
    assert_equal("Domingo",_('Sunday'))
  end
  
end