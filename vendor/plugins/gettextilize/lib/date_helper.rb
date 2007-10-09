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

require "date"

module ActionView #:nodoc:
  module Helpers #:nodoc:
    module DateHelper #:nodoc:
        # Separate namespace for textdomain
        include GetText
        extend GetText
        
        alias old_distance_of_time_in_words distance_of_time_in_words #:nodoc:
        # This is exactly the same method, but includes gettext calls, in order to
        # be able to use localized strings for distance_of_time_in_words 
        def distance_of_time_in_words(from_time, to_time = 0, include_seconds = false) #:nodoc:
          GetText.bindtextdomain('railsdatehelper')
          textdomain('railsdatehelper')

          # Have to add the path here
          from_time = from_time.to_time if from_time.respond_to?(:to_time)
          to_time = to_time.to_time if to_time.respond_to?(:to_time)
          distance_in_minutes = (((to_time - from_time).abs)/60).round
          distance_in_seconds = ((to_time - from_time).abs).round

          case distance_in_minutes
            when 0..1
              return (distance_in_minutes==0) ? _('less than a minute') : _('1 minute') unless include_seconds
              case distance_in_seconds
                when 0..5   then _('less than 5 seconds')
                when 6..10  then _('less than 10 seconds')
                when 11..20 then _('less than 20 seconds')
                when 21..40 then _('half a minute')
                when 41..59 then _('less than a minute')
                else             _('1 minute')
              end
                                  
            when 2..44      then _("%s minutes") % "#{distance_in_minutes}"
            when 45..89     then _('about 1 hour')
            when 90..1439   then _("about %s hours") % "#{(distance_in_minutes.to_f / 60.0).round}"
            when 1440..2879      then _('1 day')
            when 2880..43199     then _("%s days") % "#{(distance_in_minutes / 1440).round}"
            when 43200..86399    then _('about 1 month')
            when 86400..525959   then _("%s months") % "#{(distance_in_minutes / 43200).round}"
            when 525960..1051919 then _('about 1 year')
            else _("over %s years") % "#{(distance_in_minutes / 525960).round}"
          end
        end               
    end
  end
end
