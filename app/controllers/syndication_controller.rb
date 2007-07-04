=begin #(fold)
Copyright 2004-2007 Joyent Inc.

Redistribution and/or modification of this code is governed
by either the GPLv2 or Joyent Commercial Software licenses.

Report issues and contribute at http://dev.joyent.com/

$Id$
=end #(end)

class SyndicationController < ApplicationController
  before_filter :require_http_authentication
  before_filter :sync_mailboxes, :only => [:mail_mailbox_rss, :mail_smart_rss, :mail_notifications_rss]

  layout nil

  helper :mail, :lists
  
  def index
    render :nothing => true
  end

  # connect

  def connect_notifications_rss
    @group_name   = _('Notifications')
    notifications = User.current.current_notifications
    @items = notifications.inject([]) do |arr, notification|
      if notification.item_type == 'Message' && !notification.item.exist?
        notification.destroy rescue nil # In case it's owned by someone else
      else
        arr << notification.item
      end
      arr
    end
      
    @connector_link = connect_notifications_url(:full_path => false)
    render :action => 'connect_rss'
  end                          
  
  def connect_smart_rss
    smart_group  = SmartGroup.find(SmartGroup.param_to_id(params[:smart_group_id]), :scope => :read)
    @group_name   = smart_group.name
    if smart_group.owner != User.current
      @group_name   = _("%{i18n_owner_full_name}'s %{i18n_group_name}")%{:i18n_owner_full_name => "#{smart_group.owner.full_name}",:i18n_group_name => "#{@group_name}"}
    end
    @items        = smart_group.items
    @connector_link = connect_smart_list_url(:smart_group_id => params[:smart_group_id], :full_path => false)
    render :action => 'connect_rss'
  end      
  
  # mail

  def mail_mailbox_rss
    @mailbox       = Mailbox.find(params[:id], :scope => :read)
    @mailbox.sync
    User.selected  = @mailbox.owner
    @group_name    = _(@mailbox.name)
    if @mailbox.owner != User.current
      @group_name = _("%{i18n_owner_full_name}'s %{i18n_group_name}")%{:i18n_owner_full_name => "#{@mailbox.owner.full_name}",:i18n_group_name => "#{@group_name}"}
    end
    @messages       = @mailbox.messages.find(:all, :limit => 25, :conditions => ['messages.active = ?', true], :order => 'created_at DESC', :scope => :read)
    @connector_link = mail_mailbox_url(:id=>@mailbox, :full_path=>false)
    render :action=>'mail_rss'
  end
  
  def mail_smart_rss
    @smart_group  = SmartGroup.find(SmartGroup.param_to_id(params[:smart_group_id]), :scope => :read)
    if @smart_group.owner != User.current
      @group_name = _("%{i18n_owner_full_name}'s %{i18n_group_name}")%{:i18n_owner_full_name => "#{@smart_group.owner.full_name}",:i18n_group_name => "#{@group_name}"}
    end
    User.selected  = @smart_group.owner
    @group_name    = @smart_group.name
    @messages      = @smart_group.items(nil, 25, 0)
    @connector_link  = mail_smart_list_url(:smart_group_id=>params[:smart_group_id], :full_path=>false)
    render :action=>'mail_rss'
  end
  
  def mail_notifications_rss
    @group_name = _('Notifications')
    notifications = Organization.current.notifications.find(:all, :conditions => ["item_type = 'Message' and notifiee_id = ?", User.current.id], :limit => 25)
    @messages = notifications.inject([]) do |arr, notification|
      if !notification.item.exist?
        notification.destroy rescue nil # In case it's owned by someone else
      else
        arr << notification.item
      end
      arr
    end
    @connector_link = mail_notifications_url(:full_path=>false)
    render :action=>'mail_rss'
  end

  # calendar

  def smart_calendar_rss
    @start_date = params['start_date'] ? Date.parse(params['start_date']) : User.current.today
    @end_date   = params['end_date']   ? Date.parse(params['end_date'])   : (@start_date + 7)
    
    @smart_group = SmartGroup.find(SmartGroup.param_to_id(params[:smart_group_id]), :scope => :read)
    @group_name  = @smart_group.name
    if @smart_group.owner != User.current
      @group_name   = _("%{i18n_owner_full_name}'s %{i18n_group_name}")%{:i18n_owner_full_name => "#{@smart_group.owner.full_name}",:i18n_group_name => "#{@group_name}"}
    end
    @events      = @smart_group.items
    @events      = @events.collect{|e| e.occurrences_between(@start_date.to_time(:utc), @end_date.to_time(:utc))}.flatten.sort
    
    @connector_link = calendar_smart_month_url(:smart_group_id=>params[:smart_group_id])

    render :action=>:calendar_rss
  end
  
  def smart_calendar_ics
    @smart_group = SmartGroup.find(SmartGroup.param_to_id(params[:smart_group_id]), :scope => :read)
    @group_name  = @smart_group.name
    @events      = @smart_group.items

    send_data render_to_string(:action => 'ics', :layout => false), :filename => "#{@group_name}.ics".gsub(/[ \']/, '_')
  end
  
  def standard_calendar_ics
    @calendar   = Calendar.find(params[:calendar_id], :scope => :read)
    @group_name = @calendar.name
    @events     = @calendar.events.find(:all, :scope => :read)
    
    send_data render_to_string(:action => 'ics', :layout => false), :filename => "#{@group_name}.ics".gsub(/[ \']/, '_')
  end
  
  def standard_calendar_rss
    @start_date = params['start_date'] ? Date.parse(params['start_date']) : User.current.today
    @end_date   = params['end_date']   ? Date.parse(params['end_date'])   : (@start_date + 7)
    
    @calendar   = Calendar.find(params[:calendar_id], :scope => :read)
    @group_name = @calendar.name
    if @calendar.owner != User.current
      @group_name   = _("%{i18n_owner_full_name}'s %{i18n_group_name}")%{:i18n_owner_full_name => "#{@calendar.owner.full_name}",:i18n_group_name => "#{@group_name}"}
    end
    @events     = @calendar.events_between(@start_date.to_time(:utc), @end_date.to_time(:utc))
    
    @connector_link = calendar_month_route_url(:calendar_id=>@calendar, :only_path=>false)
    
    render :action=>'calendar_rss'
  end
  
  def notifications_calendar_ics
    @group_name = _('Notifications')
    @events     = Organization.current.notifications.find(:all, :conditions => ["item_type = 'Event' and notifiee_id = ?", User.current.id]).collect(&:item)
    send_data render_to_string(:action => 'ics', :layout => false), :filename => "#{@group_name}.ics".gsub(/[ \']/, '_')
  end
  
  def notifications_calendar_rss
    @group_name = _('Notifications')
    @events     = Organization.current.notifications.find(:all, :conditions => ["item_type = 'Event' and notifiee_id = ?", User.current.id]).collect(&:item).sort_by(&:updated_at).reverse
    
    # Don't want to deal with repeating events here b/c it is more important to know about the events that you have been notified on
    @connector_link = calendar_notifications_url(:full_path=>false)
    render :action=>'calendar_rss'
  end
  
  def all_calendar_ics
    @group_name = _('All Events')
    @events     = User.current.calendars.collect{|c| c.events}.flatten
    
    send_data render_to_string(:action => 'ics', :layout => false), :filename => "#{@group_name}.ics".gsub(/[ \']/, '_')
  end
  
  def all_calendar_rss
    @start_date = params['start_date'] ? Date.parse(params['start_date']) : User.current.today
    @end_date   = params['end_date']   ? Date.parse(params['end_date'])   : (@start_date + 7)
    
    @group_name = _('All Events')
    @events     = User.current.calendars.collect{|c| c.events_between(@start_date.to_time(:utc), @end_date.to_time(:utc))}.flatten
    @connector_link  = calendar_all_month_url(:full_path=>false)
    render :action=>'calendar_rss'
  end  

  # people

  def people_rss
    if params[:group] =~ /^\d+$/
      people_contacts_rss
    elsif params[:group] == 'users'
      people_users_rss
    elsif params[:group] == 'notifications'
      people_notifications_rss
    elsif params[:group] =~ /s(\d+)/
      people_smart_rss
    else
      redirect_to '/'
    end
  end

  def people_contacts_rss
    @contact_list = ContactList.find(params[:group], :scope => :read)
    User.selected = @contact_list.owner
    @group_name = _('Contacts')
    if @contact_list.owner != User.current
      @group_name   = _("%{i18n_owner_full_name}'s %{i18n_group_name}")%{:i18n_owner_full_name => "#{@contact_list.owner.full_name}",:i18n_group_name => "#{@group_name}"}
    end
    @people = @contact_list.people.find(:all, :scope => :read)
    @connector_link = people_list_url(:group => @contact_list, :full_path => false)
    render :action=>'people_rss'
  end
  
  def people_users_rss
    @group_name = _('Users')
    @people = Organization.current.people.select{|p| p.user}
    @connector_link = people_list_url(:group => 'users', :full_path => false)
    render :action=>'people_rss'
  end
  
  def people_notifications_rss
    @group_name = _('Notifications')
    @people = Organization.current.notifications.find(:all, :conditions => ["item_type = 'Person' and notifiee_id = ?", User.current.id]).collect(&:item)
    @connector_link = people_notifications_url(:full_path => false)
    render :action=>'people_rss'
  end
  
  def people_smart_rss
    @smart_group = SmartGroup.find(SmartGroup.param_to_id(params[:group]), :scope => :read)
    @group_name  = @smart_group.name
    if @smart_group.owner != User.current
      @group_name = _("%{i18n_owner_full_name}'s %{i18n_group_name}")%{:i18n_owner_full_name => "#{smart_group.owner.full_name}",:i18n_group_name => "#{@group_name}"}
    end
    @people = @smart_group.items
    @connector_link = people_list_url(:group => params[:group], :full_path => false)
    render :action=>'people_rss'
  end

  # files

  def files_notications_rss
    @group_name  = _("Notifications")
    @files       = Organization.current.notifications.find(:all, :conditions => ["item_type = 'JoyentFile' and notifiee_id = ?", User.current.id]).collect(&:item)
    @connector_link  = files_notifications_url(:full_path=>false)
    render :action=>'files_rss'
  end
  
  def files_standard_rss
    folder       = Folder.find(params[:folder_id], :scope => :read)
    @group_name  = folder.name
    if folder.owner != User.current
      @group_name = _("%{i18n_owner_full_name}'s %{i18n_group_name}")%{:i18n_owner_full_name => "#{folder.owner.full_name}",:i18n_group_name => "#{@group_name}"}
    end
    @files       = folder.joyent_files.find(:all, :scope => :read)
    @connector_link  = files_list_route_url(:folder_id => folder.id, :full_path => false)
    render :action=>'files_rss'
  end                   
  
  def files_smart_rss
    smart_group = SmartGroup.find(SmartGroup.param_to_id(params[:smart_group_id]), :scope => :read)
    @group_name = smart_group.name
    if smart_group.owner != User.current
      @group_name = _("%{i18n_owner_full_name}'s %{i18n_group_name}")%{:i18n_owner_full_name => "#{smart_group.owner.full_name}",:i18n_group_name => "#{@group_name}"}
    end
    @files       = smart_group.items
    @connector_link  = files_smart_list_url(:smart_group_id => params[:smart_group_id], :full_path => false)
    render :action=>'files_rss'
  end            
  
  def files_strongspace_rss
    @folder       = StrongspaceFolder.find(User.current, params[:path] || '', User.current)
    User.selected = @folder.owner
    @group_name   = @folder.name
    @files        = @folder.files

    @connector_link = files_strongspace_list_url(:owner_id => @folder.owner.id, :path => @folder.relative_path)
    
    render :action => 'files_service_rss'
  end    

  def files_service_rss
    @service = Service.find(params[:service_name], User.current)
    User.selected = @service.owner    
    @folder       = params[:group_id] ? @service.find_folder(params[:group_id]) : nil
    @folder     ||= @service.root_folder
    @group_name   = @folder.name
    @files        = @folder.files
    
    @connector_link = files_service_list_url
    
    render :action => 'files_service_rss'
  end
  
  # bookmarks
  
  def bookmarks_list_rss
    @group_name = _("Bookmarks")
    bookmark_folder = BookmarkFolder.find(params[:bookmark_folder_id], :scope => :read)
    @connector_link = bookmarks_list_route_url(:bookmark_folder_id => bookmark_folder.id)
    @bookmarks = bookmark_folder.bookmarks.find(:all, :order => 'created_at DESC', :limit => 75, :scope => :read)
    
    render :action => 'bookmarks_rss'
  end
  
  def bookmarks_list_everyone_rss
    @group_name = _("Others' Bookmarks")
    @connector_link = bookmarks_everyone_url
    @bookmarks = Bookmark.find(:all, :conditions => ["bookmarks.user_id != ?", User.current.id], :order => 'created_at DESC', :limit => 25, :scope => :read)
    
    render :action => 'bookmarks_rss'
  end
  
  def bookmarks_notifications_rss
    @group_name = _("Notifications")
    @bookmarks = User.current.notifications.find(:all, :conditions => ["item_type = 'Bookmark'"]).collect(&:item)
    @connector_link = bookmarks_notifications_url

    render :action => 'bookmarks_rss'
  end
  
  def bookmarks_smart_list_rss
    smart_group = SmartGroup.find(SmartGroup.param_to_id(params[:smart_group_id]), :scope => :read)
    @group_name = smart_group.name
    @group_name = _("%{i18n_owner_full_name}'s %{i18n_group_name}")%{:i18n_owner_full_name => "#{smart_group.owner.full_name}",:i18n_group_name => "#{@group_name}"} if smart_group.owner != User.current
    @bookmarks = smart_group.items
    @connector_link = bookmarks_smart_list_url(:smart_group_id => params[:smart_group_id], :full_path => false)
    
    render :action => 'bookmarks_rss'
  end
  
  # lists
  
  def lists_standard_rss
    group = ListFolder.find(params[:group_id], :scope => :read)
    @group_name = group.name
    if group.owner != User.current
      @group_name = "#{group.owner.full_name}'s #{@group_name}"
    end
    @lists  = List.find(:all, :conditions => ["list_folder_id = ?", group.id], :scope => :read)
    @lists_link = lists_url(:group => group.id, :full_path => false)
    render :action => 'lists_rss'
  end
  
  def lists_smart_rss
    smart_group  = SmartGroup.find(SmartGroup.param_to_id(params[:smart_group_id]), :scope => :read)
    @group_name  = smart_group.name   
    if smart_group.owner != User.current
      @group_name = "#{smart_group.owner.full_name}'s #{@group_name}" 
    end
    @lists       = smart_group.items
    @lists_link  = lists_url(:group => params[:smart_group_id], :full_path => false)
    render :action => 'lists_rss'
  end
  
  def lists_notifications_rss
    @group_name   = "Notifications"
    @lists        = Organization.current.notifications.find(:all, :conditions => ["item_type = 'List' and notifiee_id = ?", User.current.id]).collect(&:item)
    @lists_link   = lists_notifications_url(:full_path=>false)
    render :action => 'lists_rss'
  end
  
  # reports
  
  def current_time_rss
    @group_name   = _("Current Time")
    @timezones    = []
    Organization.current.users.each do |user|
      @timezones << {:user => user, :time => user.now, :timezone => user.tz.to_s}  
    end                                                
  
    @timezones.sort! do |a,b| 
      (a[:time] <=> b[:time]) != 0 ? a[:time] <=> b[:time] : a[:user].full_name <=> b[:user].full_name
    end
  end   
  
  def recent_comments_rss
    @group_name   = _('Recent Comments')
    comments      = Comment.find(:all, 
                                 :include    => 'user',
                                 :conditions => ['users.organization_id = ? AND created_at >= ?', 
                                                 Organization.current.id, 
                                                 Time.now - 7.days],
                                 :order      => 'created_at DESC')
  
    # The paginator is not perfect because it does not take into account the permissions
    # on the items, but it is better than processing each item one by one (we already
    # have to do a lot of that)                                               
    @paginator = Paginator.new(self, comments.size, 25, 1)

    # Now we need to find only the comments to the items to which I can access,  
    # and the report owner can access 
    # FIXME: This is terribly inefficient, but I don't know of a better way.  I don't think
    #        this can be done in SQL, at least not without some huge join.
    accessible_comments = []          
    current_index       = 0
    goal_count          = @paginator.current_page.last_item
    while accessible_comments.size < goal_count && current_index < comments.size
      comment = comments[current_index]
      if comment.commentable_type == 'Message' && !comment.commentable.exist?
        comments.delete_at current_index
        comment.destroy rescue nil # In case it's owned by someone else
        next
      else
        accessible_comments << comment if User.current.can_view?(comment.commentable)
      end
      current_index += 1
    end                     
                                                                
    # Actually do the pagination
    @comments = comments[@paginator.current_page.offset..-1] || [] 
    @items    = @comments.collect{|c| c.commentable}.uniq
  end 
  
  def unread_messages_rss
    User.selected  = User.find(params[:id], :scope => :read) if params.has_key?(:id)
    @mailbox       = User.selected.inbox
    @mailbox.sync
    
    @group_name    = @mailbox_name  = _("Unread Messages")
    message_count  = Message.restricted_count(:conditions => ['mailbox_id = ?', @mailbox.id])
    @paginator     = Paginator.new self, message_count, 25, 1
    @messages      = @mailbox.messages.find(:all, 
                                            :conditions => ["seen = ? OR seen IS NULL", false],
                                            :order      => "messages.date DESC",
                                            :limit      => @paginator.items_per_page,
                                            :offset     => @paginator.current.offset,
                                            :scope => :read)
  
    @connector_link  = mail_unread_messages_url(:id=>User.selected.id, :full_path=>false)
    render :action=>'mail_rss'  
  end 
  
  def todays_events_rss           
    User.selected  = User.find(params[:id], :scope => :read) if params.has_key?(:id)
    @start_date = User.selected.today
    @end_date   = @start_date + 1
    
    @group_name = _("Today's Events")
    @events     = User.selected.calendars.collect{|c| c.events_between(@start_date.to_time(:utc), @end_date.to_time(:utc))}.flatten
    @connector_link  = calendar_todays_events_url(:id => User.selected, :full_path=>false)
    render :action=>'calendar_rss'
  end                  
  
  def weeks_events_rss                                               
    User.selected  = User.find(params[:id], :scope => :read) if params.has_key?(:id)
    @start_date = User.selected.today
    @end_date   = @start_date + 7
    
    @group_name = _("This Week's Events")
    @events     = User.selected.calendars.collect{|c| c.events_between(@start_date.to_time(:utc), @end_date.to_time(:utc))}.flatten
    @connector_link  = calendar_weeks_events_url(:id => User.selected, :full_path=>false)
    render :action=>'calendar_rss'
  end            
  
  # tags

  def tag_rss
    tag       = Tag.find_by_name(params[:tag_name])
    @tag_name = params[:tag_name]
    @connector_link = connector_home_url
    @items    = []
    if tag
      @items = tag.restricted_items
    end
    render :action => 'tag_rss'
  end
  
  private

    def require_http_authentication
      unless (auth = (request.env['X-HTTP_AUTHORIZATION'] || request.env['HTTP_AUTHORIZATION'])).nil?
        auth = auth.split
        user, password = Base64.decode64(auth[1]).split(':')[0..1]
        if user = Domain.current.authenticate_user(user,password)
          User.current=user
          return true
        end
      end
      response.headers["Status"] = "Unauthorized"
      response.headers["WWW-Authenticate"] = "Basic realm=\"Feeds and Calendars from Joyent\""
      render :text => _('You must log in to access your RSS/ICS'), :status => 401
      return false
    end
    
    def sync_mailboxes
      @mailboxes    = Mailbox.list(User.current)
      @mailbox_list = User.current.mailboxes
    end

end