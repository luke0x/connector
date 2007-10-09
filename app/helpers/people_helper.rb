=begin #(fold)
++
Copyright 2004-2007 Joyent Inc.

Redistribution and/or modification of this code is 
governed by the GPLv2.

Report issues and contribute at http://dev.joyent.com/

$Id$
--
=end #(end)


module PeopleHelper

  # set the clicked star in a 'radio-button'-like group to selected
  # sets a hidden field with the value of true/false
  def mark_as_primary_star(object, object_name, method_name, index)
    content = ''

    id              = "#{object_name}_#{method_name}_#{index}_preferred"
    name            = "#{object_name}[#{method_name.pluralize}][#{index}][preferred]"
    collection_name = "#{object_name}_#{method_name.pluralize}" # the stars must be in a tbody with this id

    if object.preferred?
      content << "<div id='#{id + '_div'}' title='Currently marked as primary' class='primaryItem'>"
      content << "<input type='hidden' value='true' id='#{id}' name='#{name}' />"
      content << "</div>"
    else
      content << "<div id='#{id + '_div'}' title='Mark as primary' class='makePrimaryItem'>"
      content << "<input type='hidden' value='false' id='#{id}' name='#{name}' />"
      content << "</div>"
    end
    content << javascript_tag("Event.observe('#{id + '_div'}', 'click', function(event){People.markAsPrimary('#{id + '_div'}', '#{collection_name}');});")

    content
  end

  def tzinfo_timezone_select(object_name, method_name, default_value)
    time_zones = TZInfo::Timezone.all.sort.collect{|tz| [tz.to_s, tz.name]}
    time_zone_options = options_for_select time_zones, default_value || 'America/New_York'
    select_tag "#{object_name}[#{method_name}]", time_zone_options, { :id => "#{object_name}_#{method_name}" }
  end

  def group_parameter
    if @smart_group
      @smart_group.url_id
    elsif @contact_list
      @contact_list.id
    elsif @group_name == _('Users')
      'users'
    elsif @group_name == _('Notifications')
      'notifications'
    end
  end

end
