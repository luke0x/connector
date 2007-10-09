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

class Time #:nodoc:
  alias :strftime_nolocale :strftime

  def strftime(format) #:nodoc:
    format = format.dup
    format.gsub!(/%a/, Date::ABBR_DAYNAMES[self.wday])
    format.gsub!(/%A/, Date::DAYNAMES[self.wday])
    format.gsub!(/%b/, Date::ABBR_MONTHNAMES[self.mon])
    format.gsub!(/%B/, Date::MONTHNAMES[self.mon])
    self.strftime_nolocale(format)
  end
end

require 'date'

class Date #:nodoc:
  
  include GetText
  extend GetText
  
  # this is what ruby 1.8.6 does:
  unless RUBY_VERSION >= "1.8.6"
    
    [MONTHNAMES, DAYNAMES, ABBR_MONTHNAMES, ABBR_DAYNAMES].each do |xs|
      xs.each{|x| x.freeze}.freeze
    end
    
  end
  
  # Provides localization for Date and Months names and abbreviations
  def self.translate_strings
    # prevent usage for locales not present
    GetText.locale = 'en' unless GetText.locale && ['en','es','de','fr','it','nl'].include?(GetText.locale.language)
    GetText.bindtextdomain('datetime', File.expand_path(File.join(File.dirname(__FILE__), "../data/locale/")))
    textdomain('datetime')
        
    old_verbose, $VERBOSE = $VERBOSE, nil
    
    begin
      
      Date.const_set("MONTHNAMES", [
        nil, _("January"), _("February"), 
      _("March"), _("April"), _("May"), 
      _("June"), _("July"), _("August"), 
      _("September"), _("October"), 
      _("November"), _("December")
      ])

      Date.const_set("DAYNAMES",[
        _("Sunday"), _("Monday"), 
        _("Tuesday"), _("Wednesday"), 
        _("Thursday"), _("Friday"), 
        _("Saturday")
      ])
      Date.const_set("ABBR_MONTHNAMES",[
        nil, s_("Abbreviation|Jan"), s_("Abbreviation|Feb"), s_("Abbreviation|Mar"), 
        s_("Abbreviation|Apr"), s_("Abbreviation|May"), s_("Abbreviation|Jun"), 
        s_("Abbreviation|Jul"), s_("Abbreviation|Aug"), s_("Abbreviation|Sep"), 
        s_("Abbreviation|Oct"), s_("Abbreviation|Nov"), s_("Abbreviation|Dec")
      ])
      Date.const_set("ABBR_DAYNAMES",[
        _("Sun"), _("Mon"), _("Tue"),
        _("Wed"), _("Thu"), _("Fri"),
        _("Sat") ])
    
    ensure
      $VERBOSE = old_verbose
    end
    
  end
  
end