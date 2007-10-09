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

=begin

  Gettextilize: GetText using a Rails plugin.

  This plugin mockup some methods, just for those times the gettext gem is
  not available; it also provides some Rails specific addons, like
  a custom localization for distance_of_time_in_words and month and day names
  and abbreviations.
  
=end

module Gettextilize
end

module ActionController #:nodoc:

  module Gettextilize
    def self.included(base)
      base.extend(ClassMethods)
    end
    
    module ClassMethods #:nodoc:
      
      # loads couple more of rails localization related files.
      def localize_with_gettext(domainname, options = {}, content_type = "text/html")
          
          self.init_gettext(domainname, options)
          
          fpath = File.dirname(__FILE__)
          
          require File.join(fpath,'/date_time')
          # Date::translate_strings          
          require File.join(fpath,'/date_helper')
      end
    end
  end

end