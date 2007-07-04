#!/usr/bin/env ruby
#
#  Copyright (c) 2006-2007 Joyent Inc. 
#  Licensed under the same terms as Joyent Connector.

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