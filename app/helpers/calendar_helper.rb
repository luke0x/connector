=begin #(fold)
Copyright 2004-2007 Joyent Inc.

Redistribution and/or modification of this code is governed
by either the GPLv2 or Joyent Commercial Software licenses.

Report issues and contribute at http://dev.joyent.com/

$Id$
=end #(end)


module CalendarHelper

  VIEW_DURATION = 1.day
  MAJOR_SLOT_DURATION = 1.hour
  MINOR_SLOT_DURATION = 15.minutes

  # 'grid slots' are the html grid boxes in whatever specified precision
  def render_day_view(day_view)
    raise "Invalid grid configuration" unless MINOR_SLOT_DURATION > 0

    # an array booleans for one day's worth of hour slots
    # boolean indicates grid slot 'filled' state
    day_of_busy_grid_slots = [false] * (VIEW_DURATION / MINOR_SLOT_DURATION)

    # the array of arrays of slot filled status booleans
    day_columns = [day_of_busy_grid_slots.clone]

    columns_by_user = {}

    # find out which column to put regular events into
    day_view.users.each do |user|
      columns_by_user[user] = {}

      # go through all the regular events
      day_view.events_for_user(user).reject{ |event| event.all_day? }.each do |event|
        fit_confirmed = false
        # start by assuming the first column
        columns_by_user[user][event.id] = 0
        day_columns.each_with_index do |day_column, i|
          completely_fits = true

          # check all the slots
          day_column.each_with_index do |slot, j|
            slot_start_time = day_view.start_time + j * MINOR_SLOT_DURATION
            slot_end_time = slot_start_time + MINOR_SLOT_DURATION

            # see if this event falls in this slot
            completely_fits = false if slot and event.overlaps?(slot_start_time, slot_end_time)
          end

          # if it still completely fits, we want to put in in this col and not loop anymore
          if completely_fits
            fit_confirmed = true
            break
          else
            columns_by_user[user][event.id] += 1
          end
        end

        # create the new column if we need it
        day_columns << day_of_busy_grid_slots.clone if (columns_by_user[user][event.id] + 1) > day_columns.length

        # now mark the appropriate slots as filled for this event
        day_columns[columns_by_user[user][event.id]].each_with_index do |slot, j|
          slot_start_time = day_view.start_time + j * MINOR_SLOT_DURATION
          slot_end_time = slot_start_time + MINOR_SLOT_DURATION

          # mark the slot as filled if this event falls in this slot
          day_columns[columns_by_user[user][event.id]][j] = true if Event.overlaps?(event, slot_start_time, slot_end_time)
        end
      end
    end

    # figure out the arrangement by column instead of by event
    # { :user => { :col_index => [event1_id, event2_id] } }
    column_events_by_user = {}
    columns_by_user.partition{|user, col_hash| user == User.current}.each do |part|
      part.each do |user, col_hash|
        column_events_by_user[user] = col_hash.flip
      end
    end

    draw_day_view(column_events_by_user, day_view)
  end

  # column_events_by_user: hash by user of hash by column index of event ids
  # day_view:              the day's dayview object
  def draw_day_view(column_events_by_user, day_view)
    partial = ''
    # users in order
    users = [User.current] + column_events_by_user.keys.reject{|u| u == User.current}.sort
    # calculate total number of columns needed + change the index to a count
    main_colspan = users.collect{|user| column_events_by_user[user].keys.max}.max + 1 rescue 1
    main_column_width = 100 / main_colspan # %

    # now we print the table of events, one user per primary column
    partial << '<div class="dayView">'
    partial << '<table style="width:100%;">'
    partial << '<tr>'
    partial << '<th class="dayViewTime">'+_('Time')+'</th>'
    partial << "<th colspan=\"#{main_colspan}\" style=\"width: 100%;\">"+_('Events')+"</th>"
    partial << '<th class="dayViewMeter"></th>' # blank cell to make slots align properly
    partial << '</tr>'

    # all-day events row
    partial << '<tr>'
    partial << '<th class="dayViewTime">'+_('All Day')+'</th>'

    users.each do |user|
      user_colspan = column_events_by_user[user].length > 0 ? column_events_by_user[user].length : 1

      partial << "<td colspan=\"#{user_colspan}\" style=\"vertical-align: top; width: #{main_column_width * user_colspan}%;\">"
      day_view.events_for_user(user).select{|event| event.all_day?}.sort_by(&:name).each do |event|
        if User.current == user
          partial << '<div class="allDayEvent dayViewCurrentUserAllDayEvent">'
          partial << link_to(event.name, calendar_show_url(:id => event.id))
          partial << '</div>'
        else
          partial << '<div class="allDayEvent" style="background-color: #' + user.person.color + ';">'
          partial << link_to(event.name, calendar_show_url(:id => event.id), { :style => "background-color: ##{user.person.color};" })
          partial << '</div>'
        end
      end
      partial << '</td>'
    end

    partial << '<th class="dayViewMeter"></th>'
    partial << '</tr>'

    # step through each row of slots
    (VIEW_DURATION / MINOR_SLOT_DURATION).times do |i|
      slot_start_time = day_view.start_time + i * MINOR_SLOT_DURATION
      slot_end_time = slot_start_time + MINOR_SLOT_DURATION

      # collapse multiple slots into one html row
      raise "Invalid grid configuration" unless MAJOR_SLOT_DURATION > 0
      raise "Invalid grid configuration" unless MAJOR_SLOT_DURATION % MINOR_SLOT_DURATION == 0
      major_slot_rowspan = MAJOR_SLOT_DURATION / MINOR_SLOT_DURATION

      # add in special row classes
      row_class = case slot_start_time.strftime("%M").to_i
      when 0 then 'dayView00'
      when 15 then 'dayView15'
      when 30 then 'dayView30'
      when 45 then 'dayView45'
      else
        ''
      end
      partial << "<tr class=\"#{row_class}\">"

      if (slot_start_time - day_view.start_time) % MAJOR_SLOT_DURATION == 0
        partial << "<th rowspan=\"#{major_slot_rowspan}\" class=\"dayViewTime\">"
        partial << slot_start_time.strftime("%I:%M %p").downcase
        partial << '</th>'
      end

      # step through each column to be rendered
      main_colspan.times do |current_col_index|

        # go through each user, looking for events for this column, in user order, current user first
        users.each do |user|
          # skip if nothing
          if column_events_by_user[user].length == 0
            partial << "<td style=\"width: #{main_column_width}%;\"></td>"
            next
          end

          # now step through each column of events + figure out what to do in each column
          # step through each event for this column, and decide what to put in the slot
          # must take everything into consideration to make the right choice

          draw_start_id = nil
          draw_continuation_id = nil
          draw_empty_id = nil

          # figure out if any events are in this actual slot
          column_events_by_user[user][current_col_index].each do |event_id|
            event = day_view.events_for_user(user).detect{|e| e.id == event_id}
            # put the event in the first matching slot
            if (event.start_time_in_user_tz >= slot_start_time and event.start_time_in_user_tz < slot_end_time) or
                 (event.start_time_in_user_tz < day_view.start_time and slot_start_time == day_view.start_time)
              draw_start_id = event_id
            # do nothing on the non-starting overlaps
            elsif (event.start_time_in_user_tz <= slot_start_time and event.end_time_in_user_tz >= slot_end_time) or
                     (event.end_time_in_user_tz > slot_start_time and event.end_time_in_user_tz <= slot_end_time)
              draw_continuation_id = event_id
            # empty cells where no event overlap
            else
              draw_empty_id = event_id
            end
          end if column_events_by_user[user].has_key?(current_col_index)

          # now fill in the data for this col, by order of precedence
          if draw_start_id
            event = day_view.events_for_user(user).detect{|e| e.id == draw_start_id}
            event_rowspan = if event.duration < MINOR_SLOT_DURATION
              event.end_time_in_user_tz > slot_end_time ? 2 : 1
            else
              (event.duration / MINOR_SLOT_DURATION.to_f).ceil
            end

            if User.current == user
              partial << "<td rowspan=\"#{event_rowspan}\" class=\"dayViewEvent dayViewCurrentUserEvent\" style=\"width: #{main_column_width}%;\">"
            else
              partial << "<td rowspan=\"#{event_rowspan}\" class=\"dayViewEvent\" style=\"background-color: ##{user.person.color}; width: #{main_column_width}%;\">"
            end
            partial << link_to(event.name, calendar_show_url(:id => draw_start_id))
            partial << '</td>'
          elsif draw_continuation_id
            # do nothing
          elsif draw_empty_id
            partial << "<td style=\"width: #{main_column_width}%;\"></td>"
          else
            # shouldn't get here
          end

        end

      end

      partial << '<th class="dayViewMeter"></th>'
      partial << '</tr>'
    end

    partial << '</table>'
    partial << '</div>'

    partial
  end

  def render_month_header(title, month_view)
    raise "Header title can not be blank" if title.blank?

    new_locals = {}
    new_locals[:title]      = title
    new_locals[:month_view] = month_view
    new_locals[:jump_url]   = url_merge(controller.request.env['REQUEST_PATH'].to_s, controller.request.env['QUERY_STRING'].to_s, {'date' => 'jump_url_page_number'})

    render :partial => 'partials/month_header', :locals => new_locals
  end

  def render_calendar_list_header(title, day_views)
    raise "Header title can not be blank" if title.blank?

    new_locals = {}
    new_locals[:title]      = title
    new_locals[:day_views]  = day_views

    u = controller.request.env['REQUEST_PATH'].to_s
    q = controller.request.env['QUERY_STRING'].to_s
    duration = day_views.last.date - day_views.first.date + 1

    new_locals[:prev_url] = url_merge(u, q, { 'start_date' => (day_views.first.date - duration), 'end_date' => (day_views.first.date - 1) })
    new_locals[:next_url] = url_merge(u, q, { 'start_date' => (day_views.last.date + 1), 'end_date' => (day_views.last.date + duration) })
    new_locals[:jump_url] = url_merge(u, q, { 'date' => 'jump_url_page_number' })

    render :partial => 'partials/calendar_list_header', :locals => new_locals
  end

end
