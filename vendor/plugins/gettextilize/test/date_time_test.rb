#!/usr/bin/env ruby
#
#  Copyright (c) 2006-2007 Joyent Inc. 
#  Licensed under the same terms as Joyent Connector.

require 'test/unit'

if $0 == __FILE__
  require 'rubygems'
  if Kernel.respond_to? :gem
    gem 'gettext', '>= 1.9.0'
  else
    require_gem 'gettext', '>= 1.9.0'
  end
  require 'gettext'
  require File.expand_path(File.join(File.dirname(__FILE__),'../lib/date_time'))
end



class DateTimeTest < Test::Unit::TestCase
  
  include GetText
  extend GetText
  
  
  def setup
    
    @t = Time.utc(2000,"jan",1,20,15,1) #=> Sat Jan 01 20:15:01 UTC 2000
    
    # reset locale
    GetText.locale = nil
    
    # create a proper default locale object
    # (usually, locale should be set to the system one so, override it to ensure English)
    Locale.default = Locale::Object.new("en_GB.UTF-8")
    
  end
  
  def test_date_time_loaded
    
    GetText.locale = "es"
    
    assert Date.include?(GetText)
    # last defined constants should be returned
    assert_kind_of Array, Date::translate_strings
    
    # and now, check that localizations are in place
    
    Date.send :translate_strings
    
    t = Time.utc(2006, 12, 31, 07, 30, 24)
    
    assert_equal "Dom, 31 12 2006",t.strftime("%a, %d %m %Y")
    assert_equal "Domingo, 31 12 2006",t.strftime("%A, %d %m %Y")
    assert_equal "31 Diciembre 2006",t.strftime("%d %B %Y")
    assert_equal "31 Dic 2006",t.strftime("%d %b %Y")
  end
  
  def test_localized_times

    # default strftime behavior if no locale set
    assert_equal(@t.strftime("%a"), 'Sat')
    assert_equal(@t.strftime("%b"), 'Jan')
    assert_equal(@t.strftime("%A"), 'Saturday')
    assert_equal(@t.strftime("%B"), 'January')

    # override the locale
    GetText.locale = "es"

    # without a call to Date.translate_strings, everything remains the same
    # shouldn't add the call to translate strings into Date.initialize?
    assert_equal(@t.strftime("%a"), 'Sat')
    assert_equal(@t.strftime("%b"), 'Jan')
    assert_equal(@t.strftime("%A"), 'Saturday')
    assert_equal(@t.strftime("%B"), 'January')

    # this would raise a warning about already initialize constant,
    # that's why we're silencing warnings above
    Date.translate_strings

    # now, it should be translated
    assert_equal(@t.strftime("%a"), 'Sab')
    assert_equal(@t.strftime("%b"), 'Ene')
    assert_equal(@t.strftime("%A"), 'Sábado')
    assert_equal(@t.strftime("%B"), 'Enero')
    
  end
  
  def test_disallowed_locales
      
    GetText.locale = "ss"
    
    Date.translate_strings
    
    assert_equal(@t.strftime("%a"), 'Sat')
    assert_equal(@t.strftime("%b"), 'Jan')
    assert_equal(@t.strftime("%A"), 'Saturday')
    assert_equal(@t.strftime("%B"), 'January')
    
  end
  
  def test_allowed_locales

    GetText.locale = "fr"
    
    Date.translate_strings
          
    assert_equal(@t.strftime("%a"), 'Sam')
    assert_equal(@t.strftime("%b"), 'Jan')
    assert_equal(@t.strftime("%A"), 'Samedi')
    assert_equal(@t.strftime("%B"), 'Janvier')
    
  end
  
  def test_set_locale_after_call_translate_strings

    Date.translate_strings
    
    GetText.locale = "es"

    # now, it should be translated
    assert_not_equal(@t.strftime("%a"), 'Sab')
    assert_not_equal(@t.strftime("%b"), 'Ene')
    assert_not_equal(@t.strftime("%A"), 'Sábado')
    assert_not_equal(@t.strftime("%B"), 'Enero')

  end
  
end