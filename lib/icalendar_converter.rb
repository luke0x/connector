=begin #(fold)
++
Copyright 2004-2007 Joyent Inc.

Redistribution and/or modification of this code is 
governed by the GPLv2.

Report issues and contribute at http://dev.joyent.com/

$Id$
--
=end #(end)

require 'gettext/rails'

class IcalendarConverter
  include GetText
  bindtextdomain('connector')

  class << self
    def create_events_from_icalendar(icalendar_content)
      # Parse the vcard file
      icals = Vpim::Icalendar.decode(icalendar_content)
    
      icals.collect do |ical|
        ical.components(Vpim::Icalendar::Vevent).collect do |vevent|
          event = Event.new
          event.all_day               = (vevent.duration == 1.day || vevent.duration == 0) && (vevent.dtstart == vevent.dtstart.at_midnight)
          event.start_time_in_user_tz = localize_start_time(vevent)
          event.end_time_in_user_tz   = event.start_time_in_user_tz + vevent.duration
          event.name                  = vevent.summary.blank? ? _('Untitled Event') : vevent.summary
          event.location              = vevent.location
          event.notes                 = vevent.description || ''
          
          if rrule = vevent.propvalue('RRULE')
            # Extract the pieces of info from the recurrence rule
            supported_frequencies = ['DAILY', 'WEEKLY', 'FORTNIGHTLY', 'MONTHLY', 'YEARLY']
            until_time = $1          if rrule =~ /UNTIL=([^;]+)/i
            frequency  = $1.upcase   if rrule =~ /FREQ=([^;]+)/i
            interval   = $1.to_i     if rrule =~ /INTERVAL=([^;]+)/i
            count      = $1.to_i     if rrule =~ /COUNT=([^;]+)/i
            by_day     = $1.downcase if rrule =~ /BYDAY=([^;]+)/i

            supported_by_day_values = ['su','mo','tu','we','th','fr','sa']
            if ! by_day.blank? and by_day.split(',').all?{|i| supported_by_day_values.include?(i)}
              event.by_day = by_day.split(',')
            end
            
            # A comma means something more complex than we can handle, so we won't
            # NOTE: We are making the assumption that the inclusion of the BYMONTHDAY or BYDAY 
            #       type attributes are not altering the pattern...basically, assuming that
            #       the 'start_time' is an actual occurence of the event
            has_comma  = rrule.include?(',')
            
            # Fortnightly is not a supported term, so we will force it here
            if interval == 2 && frequency == 'WEEKLY'
              interval  = 1
              frequency = 'FORTNIGHTLY'
            end
            
            if !has_comma && (!interval || interval == 1) && !count && frequency && supported_frequencies.include?(frequency)
              # We only know how to handle a frequency by itself with or without an until time
              event.recurrence_description_id = Event.recurrence_map[frequency.downcase]
              event.recur_end_time_in_user_tz = localize_until_time(until_time)
            elsif !has_comma && !until_time && interval == 1 && 
                  count && count > 0 && frequency && supported_frequencies.include?(frequency)
              # We need to determine the 'end time' based on the count times, but we know the frequency
              event.recurrence_description_id = Event.recurrence_map[frequency.downcase]
              
              # The idea here is that if we are too high on the number of recurrences that is ok, because
              # unless there are 30+ recurrences, we will always fall in the right range.  For example, if we
              # say every 1st of the month for 5 months, and we add 31 each time, we may get an end date of
              # 5 months later on the 3rd.  This is better than 4 months later on the 29th.  As a result, this is
              # not 100% accurate, but it should be good enough
              # Note: We subtract 1 from count because a count of 1 ends the same day it starts
              count -= 1
              delta_days = case frequency
                when 'DAILY'       then count
                when 'WEEKLY'      then count * 7    
                when 'FORTNIGHTLY' then count * 14
                when 'MONTHLY'     then count * 31
                when 'YEARLY'      then count * 366
              end
              
              # Adjust the time by 1 second
              event.recur_end_time_in_user_tz = event.start_time_in_user_tz + delta_days.days + 1
            elsif by_day
              # they are using the BYDAY custom repeat
              event.recur_end_time_in_user_tz = localize_until_time(until_time)
              event.recurrence_description_id = Event.recurrence_map[frequency.downcase]
            else
              # We do not understand any other recurrence patterns so we just ignore it
              event.notes += "\n--\nJoyent Note: This imported event's repeat rule is unsupported. [#{rrule}]"
            end
          end
          event
        end
      end.flatten
    rescue => e
      RAILS_DEFAULT_LOGGER.error "Exception with import #{e}"
      raise 
    end
    
    #######
    private
    #######
    
    # The goal of this method is to respect the timezone on the start time if it exists
    def localize_start_time(vevent)
      time     = vevent.dtstart
      raw      = vevent.properties.field('dtstart').to_s
      utc_time = nil

      # The timezone could be encoded in a few different ways
      if raw =~ /tzid=([^:]+)/i
        # In case there is an explicit encoding of the timezone
        begin
          timezone = TZInfo::Timezone.get($1)
          utc_time = timezone.local_to_utc(time)
        rescue 
          # The timezone was invalid
        end 
      elsif raw =~ /([+-])(\d\d):?(\d\d)$/
        # In case the time ends with a timezone offset ex.20060601T110000-07:00
        offset   = "#{$1}#{($2.to_i*1.hour)+($3.to_i*1.minute)}".to_i
        utc_time = time - offset  
      elsif raw =~ /Z$/
        # In case the time is in UTC as denoted by a trailing 'Z' ex.20060601T110000Z
        utc_time = time   
      end

      # Finally convert the time to the user's local time
      if utc_time && User.current
        time = User.current.person.tz.utc_to_local(utc_time)
      end

      time
    end
    
    # FIXME: This could use some love.  It seems that this is not happy in Sunbird and even iCal gives
    #        crappy times.  For this reason, I have left this method with some duplicate code
    #        from the method above.
    # The best we can do with the until_time is to respect what is written and 
    # encode accordingly.  It is unfortunate because iCal encodes the until time
    # as a time in UTC, but converted from 'local time at midnight'.  So, the
    # until time could be in the next day, even though the event will not repeat at
    # that time (ex. UNTIL=20060506T065959Z -- is intended to mean end of day on the 5th)
    def localize_until_time(until_time)
      if until_time
        time     = until_time.to_time
        utc_time = nil
      
        if !(until_time =~ /T/)
          # If we just had a date component, I don't know that we can really do much else b/c
          # we don't have enough information as to whether this is a local date or a utc date
          # As a result, we just accept it as is (iCal only uses this form for all day events which
          # works for us, and Sunbird uses this form for all events which are 'user local' dates
          # for which we have no additional information)
        elsif until_time =~ /([+-])(\d\d):?(\d\d)$/
          # In case the time ends with a timezone offset ex.20060601T110000-07:00
          offset   = "#{$1}#{($2.to_i*1.hour)+($3.to_i*1.minute)}".to_i
          utc_time = time - offset  
        elsif until_time =~ /Z$/
          # In case the time is in UTC as denoted by a trailing 'Z' ex.20060601T110000Z
          utc_time = time   
        end
      
        # Finally convert the time to the user's local time
        if utc_time && User.current
          time = User.current.person.tz.utc_to_local(utc_time)
        end
      end
      
      time
    end
  end
end
