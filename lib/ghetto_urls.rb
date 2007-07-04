=begin #(fold)
Copyright 2004-2007 Joyent Inc.

Redistribution and/or modification of this code is governed
by either the GPLv2 or Joyent Commercial Software licenses.

Report issues and contribute at http://dev.joyent.com/

$Id$
=end #(end)

# extra 'routes'

module GhettoUrls
  def self.included(base)
    base.class_eval <<-EOF
      GhettoUrls.instance_methods(false).each do |meth|
        helper_method meth
      end
    EOF
  end

  # all-app methods

  def standard_list_url(standard_group)
    case standard_group
    when Mailbox           then mail_mailbox_url(:id => standard_group.id)
    when Calendar          then calendar_month_route_url(:calendar_id => standard_group.id)
    when ContactList       then people_list_url(:group => standard_group.id)
    when Folder            then files_list_route_url(:folder_id => standard_group.id)
    when StrongspaceFolder then files_strongspace_list_url(:owner_id => standard_group.owner.id, :path => standard_group.relative_path)
    when ServiceFolder     then files_service_list_url(:service_name => standard_group.service.name, :group_id => standard_group.id)
    when ListFolder        then lists_url(:group => standard_group.id)
    when BookmarkFolder    then bookmarks_list_route_url(:bookmark_folder_id => standard_group.id)
    end
  end

  def smart_list_url(smart_group_id)
    case @application_name
    when 'connect'   then connect_smart_list_url(:smart_group_id => smart_group_id)
    when 'mail'      then mail_smart_list_url(:smart_group_id => smart_group_id)
    when 'calendar'  then calendar_smart_month_url(:smart_group_id => smart_group_id)
    when 'people'    then people_list_url(:group => smart_group_id)
    when 'files'     then files_smart_list_url(:smart_group_id => smart_group_id)
    when 'bookmarks' then bookmarks_smart_list_url(:smart_group_id => smart_group_id)
    when 'lists'     then lists_url(:group => smart_group_id)
    end
  end

  def item_delete_url
    '/'
  end
  
  def item_move_url
    '/'  
  end
                              
  def item_copy_url
    '/'  
  end

  # connect

  def connect_list_url
    if @smart_group
      connect_smart_list_url(:smart_group_id => @smart_group.url_id)
    else
      ''
    end
  end

  # calendar

  def calendar_list_url(start_date = nil, end_date = nil)
    start_date ||= @start_date
    end_date ||= @end_date
    
    if @smart_group
      calendar_smart_list_url(:smart_group_id => @smart_group.url_id, :start_date => start_date.to_s, :end_date => end_date.to_s)
    elsif @calendar
      calendar_list_route_url(:calendar_id => @calendar.id, :start_date => start_date.to_s, :end_date => end_date.to_s)
    elsif @group_name == _('All Events')
      calendar_all_list_url(:start_date => start_date.to_s, :end_date => end_date.to_s)
    else
      ''
    end
  end

  def calendar_month_url
    if @smart_group
      calendar_smart_month_url(:smart_group_id => @smart_group.url_id, :date => @start_date.to_s)
    elsif @calendar
      calendar_month_route_url(:calendar_id => @calendar.id, :date => @start_date.to_s)
    elsif @group_name == _('All Events')
      calendar_all_month_url(:date => @start_date.to_s)
    else
      ''
    end
  end

  def calendar_show_url(url_options = {})
    if @smart_group
      calendar_smart_show_url(:smart_group_id => @smart_group.url_id, :id => url_options[:id])
    elsif @calendar
      calendar_show_route_url(:calendar_id => @calendar.id, :id => url_options[:id])
    elsif @group_name == _('All Events')
      calendar_all_show_url(:id => url_options[:id])
    elsif url_options[:id]   
      event = Event.find(url_options[:id], :scope => :read)
      calendar_show_route_url(:calendar_id => event.primary_calendar.id, :id => url_options[:id], :chart_date => url_options[:chart_date])
    else
      ''
    end
  end

  def calendar_edit_url(url_options = {})
    if @smart_group
      calendar_smart_edit_url(:smart_group_id => @smart_group.url_id, :id => url_options[:id])
    elsif @calendar
      calendar_edit_route_url(:calendar_id => @calendar.id, :id => url_options[:id])
    elsif @group_name == _('All Events')
      calendar_all_edit_url(:id => url_options[:id])
    elsif url_options[:id]
      event = Event.find(url_options[:id], :scope => :edit)
      calendar_edit_route_url(:calendar_id => event.primary_calendar.id, :chart_date => url_options[:chart_date])
    else
      ''
    end
  end

  def calendar_day_url(url_options = {})
    if @smart_group
      calendar_smart_day_url(:smart_group_id => @smart_group.url_id, :chart_date => url_options[:chart_date])
    elsif @calendar
      calendar_day_route_url(:calendar_id => @calendar.id, :chart_date => url_options[:chart_date])
    elsif @group_name == _('All Events')
      calendar_all_day_url(:chart_date => url_options[:chart_date])
    else
      calendar_all_day_url(:chart_date => url_options[:chart_date])
    end
  end

  # files

  def files_list_url
    if @smart_group
      files_smart_list_url(:smart_group_id => @smart_group.url_id)
    elsif @folder
      files_list_route_url(:folder_id => @folder.id)
    else
      ''
    end
  end

  def files_show_url(url_options = {})
    if @smart_group
      files_smart_show_url(:smart_group_id => @smart_group.url_id, :id => url_options[:id])
    elsif @folder
      files_show_route_url(:folder_id => @folder.id, :id => url_options[:id])
    elsif url_options[:id]
      file = JoyentFile.find(url_options[:id], :scope => :read)
      files_show_route_url(:folder_id => file.folder.id, :id => file.id)
    else
      ''
    end
  end

  def files_edit_url(url_options = {})
    if @smart_group
      files_smart_edit_url(:smart_group_id => @smart_group.url_id, :id => url_options[:id])
    elsif @folder
      files_edit_route_url(:folder_id => @folder.id, :id => url_options[:id])
    elsif url_options[:id]
      file = JoyentFile.find(url_options[:id], :scope => :edit)
      files_edit_route_url(:folder_id => file.folder.id, :id => file.id)
    else
      ''
    end
  end

  # lists
  
  def lists_list_url
    if @smart_group
      lists_url(:group => @smart_group.url_id)
    elsif @list_folder
      lists_url(:group => @list_folder.id)
    else
      lists_url(:group => 'all')
    end      
  end
  
end