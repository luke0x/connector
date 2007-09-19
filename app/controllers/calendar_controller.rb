=begin #(fold)
Copyright 2004-2007 Joyent Inc.

Redistribution and/or modification of this code is governed
by either the GPLv2 or Joyent Commercial Software licenses.

Report issues and contribute at http://dev.joyent.com/

$Id$
=end #(end)

class CalendarController < AuthenticatedController
  before_filter :setup_calendar
#  after_filter(:only => [:create_calendar, :rename_group, :delete_group, :reparent_group]){ |c| c.expire_fragment %r{calendar/sidebar} }

  def self.group_name
    'Calendar'
  end

  def item_class_name
    'Event'
  end

  def current_group_id
    if    @smart_group then @smart_group.url_id
    elsif @calendar    then @calendar.id
    elsif @group_name  then @group_name
    else  nil
    end
  end

  def index
    redirect_to calendar_all_month_url
  end

  def list
    @view_kind = 'list'
    @toolbar[:list] = false
    @start_date = params['start_date'] ? Date.parse(params['start_date']) : current_user.today
    @end_date   = params['end_date']   ? Date.parse(params['end_date'])   : (@start_date + 7)
    @paginator  = Paginator.new self, 1, JoyentConfig.page_limit, 1

    @calendar          = Calendar.find(params[:calendar_id], :scope => :read)
    self.selected_user = @calendar.owner
    @group_name        = @calendar.name
    @events            = @calendar.events_between(@start_date.to_time(:utc), @end_date.to_time(:utc))
    @day_views         = group_into_day_views(@events, @start_date, @end_date)

    @toolbar[:new_on] = current_user.can_create_on?(@calendar)
    @toolbar[:new]    = !@toolbar[:new_on]
    @toolbar[:move]   = current_user.can_move_from?(@calendar)
    @toolbar[:copy]   = current_user.can_copy_from?(@calendar)
    @toolbar[:delete] = current_user.can_delete_from?(@calendar)
    
    unless request.xhr?
      @overlay_events = get_overlay_events(@start_date.to_time(:utc), @end_date.to_time(:utc))
      setup_users_overlay
      @day_views.each do |day_view|
        @overlay_events.each do |user_id, events|
          day_view.take_others_events(user_id, events)
        end
      end
    end

    respond_to do |wants|
      wants.html
      wants.js { render :partial => 'reports/events', :locals  => {:day_views => @day_views} }
    end
  rescue ActiveRecord::RecordNotFound
    redirect_to calendar_home_url
  end

  def month
    @view_kind = 'month'
    month_date = Date.parse(params['date']) rescue current_user.today
    @month_view = MonthView.new(month_date)

    @calendar          = Calendar.find(params[:calendar_id], :scope => :read)
    self.selected_user = @calendar.owner
    @group_name        = @calendar.name
    @events            = @calendar.events_between(@month_view.start_time, @month_view.end_time)
    @toolbar[:month]   = false
    @toolbar[:new_on]  = current_user.can_create_on?(@calendar)
    @toolbar[:new]     = !@toolbar[:new_on]

    @month_view.add_events(@events)
    @start_date = month_date.to_time.beginning_of_month.to_date
    @end_date   = month_date.to_time.end_of_month.to_date

    @overlay_events = get_overlay_events(@month_view.start_time, @month_view.end_time)
    setup_users_overlay
    @overlay_events.each do |user_id, events|
      @month_view.add_others_events(user_id, events)
    end
  rescue ActiveRecord::RecordNotFound
    redirect_to calendar_home_url
  end     
  
  # Copied from all_list in calendar_controller
  def todays_events        
    events_report(_("Today's Events"), 1)
  end              

  def weeks_events
    events_report(_("This Week's Events"), 7)    
  end

  def day
    @start_date = Date.parse(params[:chart_date])
    @end_date   = @start_date + 1

    @calendar          = Calendar.find(params[:calendar_id], :scope => :read)
    self.selected_user = @calendar.owner
    @group_name        = @calendar.name
    @events            = @calendar.events_between(@start_date.to_time(:utc), @end_date.to_time(:utc))

    @overlay_events = get_overlay_events(@start_date.to_time(:utc), @end_date.to_time(:utc))
    setup_users_overlay

    @day_views = group_into_day_views(@events, @start_date, @end_date)
    @day_views.each do |day_view|
      @overlay_events.each do |user_ui, events|
        day_view.take_others_events(user_ui, events)
      end
    end

    render :partial => 'day', :locals => { :day_view => @day_views.first }
  end

  def show
    @view_kind = 'show'
    @calendar          = Calendar.find(params[:calendar_id], :scope => :read)
    self.selected_user = @calendar.owner
    @group_name        = @calendar.name
    @event             = @calendar.event_find(params[:id]) # TODO: get rid of this lameness
    @start_date        = @event.start_time_in_user_tz.to_date if @event
    @end_date          = @event.end_time_in_user_tz.to_date if @event

    @toolbar[:new_on] = current_user.can_create_on?(@calendar)
    @toolbar[:new]    = !@toolbar[:new_on]
    @toolbar[:edit]   = current_user.can_edit?(@event)
    @toolbar[:move]   = current_user.can_move?(@event)
    @toolbar[:copy]   = current_user.can_copy?(@event)
    @toolbar[:delete] = current_user.can_delete?(@event)

    if @event
      respond_to do |wants|
        wants.html { render :action => 'show' }
        wants.js   { render :update do |page|
          page[params[:update_id]].replace_html :partial => 'peek'
        end }
      end
    else
      redirect_to calendar_home_url
    end
  rescue ActiveRecord::RecordNotFound
    redirect_to calendar_home_url
  end

  def external_show
    @event    = Event.find(params[:id], :scope => :read)
    @calendar = @event.primary_calendar
    @calendar ||= @event.calendars.first

    redirect_to calendar_show_route_url(:calendar_id => @calendar, :id => @event)
  end

  def edit
    @view_kind         = 'edit'
    @calendar          = Calendar.find(params[:calendar_id], :scope => :read)
    self.selected_user = @calendar.owner
    @group_name        = @calendar.name
    @event             = Event.find(params[:id], :scope => :edit)
    @start_date        = @event.start_time_in_user_tz.to_date if @event
    @end_date          = @event.end_time_in_user_tz.to_date if @event
    
    @toolbar[:new_on] = current_user.can_create_on?(@calendar)
    @toolbar[:new]    = !@toolbar[:new_on]
    @toolbar[:move]   = current_user.can_move?(@event)
    @toolbar[:copy]   = current_user.can_copy?(@event)
    @toolbar[:delete] = current_user.can_delete?(@event)

    if request.post? && @event.update_from_params(params[:event])
      redirect_to calendar_show_url(:id => @event.id)
      return true
    elsif request.post?
      flash[:error] = "Invalid date or time."
    end
  rescue ActiveRecord::RecordNotFound
    redirect_to calendar_home_url
  end

  def move
    event_ids = params[:id] ? Array(params[:id]) : params[:ids].split(',')
    calendar  = Calendar.find(params[:new_group_id], :scope => :create_on)

    if event_ids && calendar
      event_ids.each do |event_id|
        # The event doesn't have to be owned by the user b/c many users can have the same
        # event in their different calendars, move_to will make sure the user can move it
        if event = Event.find(event_id, :scope => :move)
          event.move_to(calendar)
        end
      end

      if event_ids.size > 1
        redirect_to calendar_list_route_url(:calendar_id => calendar.id)
      else
        redirect_to calendar_show_route_url(:calendar_id => calendar.id, :id => event_ids[0])
      end
    else
      redirect_to calendar_home_url
    end
  end     
  
  def copy
    event_ids = params[:id] ? Array(params[:id]) : params[:ids].split(',') 
    calendar  = Calendar.find(params[:new_group_id], :scope => :create_on)
    new_event = nil
           
    if event_ids && calendar    
      event_ids.each do |event_id|
        if event = Event.find(event_id, :scope => :copy)
          new_event = event.copy_to(calendar)
        end
      end
         
      if event_ids.size > 1
        redirect_to calendar_list_route_url(:calendar_id => calendar.id)
      elsif new_event
        redirect_to calendar_show_route_url(:calendar_id => calendar.id, :id => new_event.id)
      else           
        redirect_to calendar_home_url      
      end
    else           
      redirect_to calendar_home_url      
    end
  end

  def all_list
    @view_kind = 'list'
    @toolbar[:list]   = false
    @toolbar[:move]   = true
    @toolbar[:copy]   = true
    @toolbar[:delete] = true
    
    @start_date = params['start_date'] ? Date.parse(params['start_date']) : current_user.today
    @end_date   = params['end_date']   ? Date.parse(params['end_date'])   : (@start_date + 7)
    @paginator  = Paginator.new self, 1, JoyentConfig.page_limit, 1

    @group_name = _('All Events')
    @events     = current_user.calendars.collect{|c| c.events_between(@start_date.to_time(:utc), @end_date.to_time(:utc))}.flatten
    @day_views  = group_into_day_views(@events, @start_date, @end_date)
    
    unless request.xhr?    
      @overlay_events = get_overlay_events(@start_date.to_time(:utc), @end_date.to_time(:utc))
      setup_users_overlay  
      @day_views.each do |day_view|
        @overlay_events.each do |user_id, events|
          day_view.take_others_events(user_id, events)
        end
      end
    end

    respond_to do |wants|
      wants.html { render :action  => 'list' }
      wants.js { render :partial => 'reports/events', :locals  => {:day_views => @day_views} }
    end
  end

  def all_month
    @view_kind = 'month'
    @toolbar[:month]  = false
    month_date  = Date.parse(params['date']) rescue current_user.today
    @month_view = MonthView.new(month_date)

    @group_name = _('All Events')
    @events     = current_user.calendars.collect{|c| c.events_between(@month_view.start_time, @month_view.end_time)}.flatten
    @month_view.add_events(@events)
    @start_date = month_date.to_time.beginning_of_month.to_date
    @end_date   = month_date.to_time.end_of_month.to_date

    @overlay_events = get_overlay_events(@month_view.start_time, @month_view.end_time)
    setup_users_overlay
    @overlay_events.each do |user_id, events|
      @month_view.add_others_events(user_id, events)
    end

    render :action => 'month'
  end

  def all_day
    @start_date = Date.parse(params[:chart_date])      
    @end_date   = @start_date + 1

    @group_name = _('All Events')
    @events     = current_user.calendars.collect{|c| c.events_between(@start_date.to_time(:utc), @end_date.to_time(:utc))}.flatten

    @overlay_events = get_overlay_events(@start_date.to_time(:utc), @end_date.to_time(:utc))
    setup_users_overlay

    @day_views = group_into_day_views(@events, @start_date, @end_date)
    @day_views.each do |day_view|
      @overlay_events.each do |user_ui, events|
        day_view.take_others_events(user_ui, events)
      end
    end

    render :partial => 'day', :locals => { :day_view => @day_views.first }
  end

  def all_show
    @view_kind = 'show'
    @group_name       = _('All Events')
    @event            = Event.find(params[:id], :scope => :read)
    @start_date       = @event.start_time_in_user_tz.to_date if @event
    @end_date         = @event.end_time_in_user_tz.to_date if @event

    @toolbar[:edit]   = current_user.can_edit?(@event)
    @toolbar[:move]   = current_user.can_move?(@event)
    @toolbar[:copy]   = current_user.can_copy?(@event)
    @toolbar[:delete] = current_user.can_delete?(@event)

    if @event
      respond_to do |wants|
        wants.html { render :action => 'show' }
        wants.js   { render :update do |page|
          page[params[:update_id]].replace_html :partial => 'peek'
        end }
      end
    else
      redirect_to calendar_all_month_url
    end
  rescue ActiveRecord::RecordNotFound
    redirect_to calendar_all_month_url
  end

  def all_edit
    @view_kind = 'edit'
    @group_name       = _('All Events')
    @event            = Event.find(params[:id], :scope => :edit)
    @start_date       = @event.start_time_in_user_tz.to_date if @event
    @end_date         = @event.end_time_in_user_tz.to_date if @event
    @toolbar[:move]   = current_user.can_move?(@event)
    @toolbar[:copy]   = current_user.can_copy?(@event)
    @toolbar[:delete] = current_user.can_delete?(@event)

    if request.post? && @event.update_from_params(params[:event])
      redirect_to calendar_all_show_url(:id => @event.id)
      return true
    elsif request.post?
      flash[:error] = "Invalid date or time."
    end

    render :action => 'edit'              
  rescue ActiveRecord::RecordNotFound
    redirect_to calendar_all_list_url
  end

  # TODO: This could be made viewable by other people if we wanted... 
  # TODO: Would be nice to invoke the notifications/list action without redirecting there
  def notifications
    @view_kind = 'notifications'
    @toolbar[:list] = false
    @toolbar[:month] = false
    @toolbar[:today] = false
    @toolbar[:import] = false
    notice_count = current_user.notifications_count('Event', params.has_key?(:all))
    @paginator = Paginator.new self, notice_count, JoyentConfig.page_limit, params[:page]

    if params.has_key?(:all)
      @group_name = _('All Notifications')
      @show_all = true
      @notifications = selected_user.notifications.find(:all, 
                                                        :conditions => ["notifications.item_type = 'Event' "],
                                                        :include    => {:notifier => [:person]},
                                                        :order      => "notifications.created_at DESC",
                                                        :limit      => @paginator.items_per_page, 
                                                        :offset     => @paginator.current.offset)
      @toolbar[:new_notifications] = true
    else
      @group_name = _('Notifications')
      @show_all = false
      @notifications = selected_user.current_notifications.find(:all, 
                                                                :conditions => ["notifications.item_type = 'Event' "], 
                                                                :include    => {:notifier => [:person]},
                                                                :order      => "notifications.created_at DESC",
                                                                :limit      => @paginator.items_per_page, 
                                                                :offset     => @paginator.current.offset)
      @toolbar[:all_notifications] = true
    end

    respond_to do |wants|
      wants.html { render :template => 'notifications/list' }
      wants.js   { render :partial  => 'reports/notifications', 
                          :locals   => {:show_all => @show_all} }
    end
  end

  def invitations_accept                                             
    calendar = if params[:calendar_type] == 'existing'
      Calendar.find(params[:calendar_id], :scope => :create_on)
    elsif params[:new_calendar]
      current_user.calendars.create(:name => params[:new_calendar].strip, :parent_id => nil, :organization_id => current_organization.id)
    end

    event = Event.find(params[:id], :scope => :read)
    if calendar && event
      invitation = event.invitation_for(current_user)
      invitation.accept!(calendar) if invitation && calendar
    end
  ensure
    redirect_back_or_home
  end
  
  def invitations_decline
    event      = Event.find(params[:id], :scope => :read)
    invitation = event.invitation_for(current_user)
    invitation.decline! if invitation
  ensure
    redirect_back_or_home
  end

  def smart_list
    @view_kind  = 'list'
    @start_date = params['start_date'] ? Date.parse(params['start_date']) : current_user.today
    @end_date   = params['end_date']   ? Date.parse(params['end_date'])   : (@start_date + 7)  
    @paginator  = Paginator.new self, 1, JoyentConfig.page_limit, 1

    @smart_group       = SmartGroup.find(SmartGroup.param_to_id(params[:smart_group_id]), :scope => :read)
    self.selected_user = @smart_group.owner
    @group_name        = @smart_group.name
    @events            = @smart_group.items
    @events            = @events.collect{|e| e.occurrences_between(@start_date.to_time(:utc), @end_date.to_time(:utc))}.flatten.sort
    @day_views         = group_into_day_views(@events, @start_date, @end_date)

    @toolbar[:list]   = false
    @toolbar[:move]   = current_user.can_move_from?(@smart_group)
    @toolbar[:copy]   = current_user.can_copy_from?(@smart_group)
    @toolbar[:delete] = current_user.can_delete_from?(@smart_group)
    
    unless request.xhr?                            
      @overlay_events = get_overlay_events(@start_date.to_time(:utc), @end_date.to_time(:utc))
      setup_users_overlay
      @day_views.each do |day_view|
        @overlay_events.each do |user_id, events|
          day_view.take_others_events(user_id, events)
        end
      end
    end

    respond_to do |wants|
      wants.html { render :action  => 'list'  }
      wants.js { render :partial => 'reports/events', :locals  => {:day_views => @day_views} }
    end
  rescue ActiveRecord::RecordNotFound
    redirect_to calendar_home_url
  end

  def smart_month
    @view_kind = 'month'
    @toolbar[:month]  = false 
    month_date = Date.parse(params['date']) rescue current_user.today
    @month_view = MonthView.new(month_date)

    @smart_group       = SmartGroup.find(SmartGroup.param_to_id(params[:smart_group_id]), :scope => :read)
    self.selected_user = @smart_group.owner
    @group_name        = @smart_group.name
    @events            = @smart_group.items
    @events            = @events.collect{|e| e.occurrences_between(@month_view.start_time, @month_view.end_time)}.flatten.sort
    
    @month_view.add_events(@events)           
    @start_date = month_date.to_time.beginning_of_month.to_date
    @end_date   = month_date.to_time.end_of_month.to_date

    @overlay_events = get_overlay_events(@month_view.start_time, @month_view.end_time)
    setup_users_overlay
    @overlay_events.each do |user_id, events|
      @month_view.add_others_events(user_id, events)
    end

    render :action => 'month'
  rescue ActiveRecord::RecordNotFound
    redirect_to calendar_home_url
  end

  def smart_day
    @start_date = Date.parse(params[:chart_date])      
    @end_date   = @start_date + 1

    @smart_group       = SmartGroup.find(SmartGroup.param_to_id(params[:smart_group_id]), :scope => :read)
    self.selected_user = @smart_group.owner
    @group_name        = @smart_group.name
    @events            = @smart_group.items
    @events            = @events.collect{|e| e.occurrences_between(@start_date.to_time(:utc), @end_date.to_time(:utc))}.flatten.sort

    @overlay_events = get_overlay_events(@start_date.to_time(:utc), @end_date.to_time(:utc))
    setup_users_overlay

    @day_views = group_into_day_views(@events, @start_date, @end_date)
    @day_views.each do |day_view|
      @overlay_events.each do |user_ui, events|
        day_view.take_others_events(user_ui, events)
      end
    end

    render :partial => 'day', :locals => { :day_view => @day_views.first }
  rescue ActiveRecord::RecordNotFound
    redirect_to calendar_home_url
  end

  def smart_show
    @view_kind    = 'show'
    @smart_group  = SmartGroup.find(SmartGroup.param_to_id(params[:smart_group_id]), :scope => :read)
    if @smart_group
      self.selected_user = @smart_group.owner
      @group_name        = @smart_group.name
      @event             = Event.find(params[:id], :scope => :read)
      @start_date        = @event.start_time_in_user_tz.to_date if @event
      @end_date          = @event.end_time_in_user_tz.to_date if @event

      @toolbar[:edit]   = current_user.can_edit?(@event) 
      @toolbar[:move]   = current_user.can_move?(@event)
      @toolbar[:copy]   = current_user.can_copy?(@event)
      @toolbar[:delete] = current_user.can_delete?(@event)

      if @event
        respond_to do |wants|
          wants.html { render :action => 'show' }
          wants.js   { render :update do |page|
            page[params[:update_id]].replace_html :partial => 'peek'
          end }
        end
      else
        redirect_to calendar_home_url
      end
    else
      redirect_to calendar_home_url   
    end  
  rescue ActiveRecord::RecordNotFound
    redirect_to calendar_home_url
  end

  def smart_edit
    @view_kind         = 'edit'
    @smart_group       = SmartGroup.find(SmartGroup.param_to_id(params[:smart_group_id]), :scope => :read)
    self.selected_user = @smart_group.owner
    @group_name        = @smart_group.name
    @event             = Event.find(params[:id], :scope => :edit)
    @start_date        = @event.start_time_in_user_tz.to_date if @event
    @end_date          = @event.end_time_in_user_tz.to_date if @event

    @toolbar[:move]   = current_user.can_move?(@event)
    @toolbar[:copy]   = current_user.can_copy?(@event)
    @toolbar[:delete] = current_user.can_delete?(@event)
    
    if request.post? && @event.update_from_params(params[:event])
      redirect_to calendar_smart_show_url(:smart_group_id => @smart_group.url_id, :id => @event.id)
      return true
    elsif request.post?
      flash[:error] = "Invalid date or time."
    end

    render :action => 'edit'            
  rescue ActiveRecord::RecordNotFound
    redirect_to calendar_smart_list_url
  end

  # other

  def create
    @view_kind = 'create'
    @toolbar[:new] = false
    begin
      @calendar = Calendar.find(params[:calendar_id], :scope => :create_on)
    rescue ActiveRecord::RecordNotFound
      @calendar = current_user.calendars.first
    end
    @group_name = @calendar.name
    @start_date = @end_date = current_user.today

    @event = Event.new

    # save it
    if request.post? && @event.update_from_params(params[:event])
      @calendar.add_event(@event)

      params[:new_item_tags].split(',,').each do |tag_name|
        current_user.tag_item(@event, tag_name)
      end unless params[:new_item_tags].blank?
      params[:new_item_permissions].split(',').each do |user_dom_id|
        next unless user = find_by_dom_id(user_dom_id)
        @event.add_permission(user)
      end unless params[:new_item_permissions].blank?
      params[:new_item_notifications].split(',').each do |user_dom_id|
        next unless user = find_by_dom_id(user_dom_id)
        user.notify_of(@event, current_user)
      end unless params[:new_item_notifications].blank?

      redirect_to calendar_show_url(:id => @event.id)
      return true
    elsif request.post?
      flash[:error] = "Invalid date or time."
    end
    
    # preset defaults                
    date = params['date'] || @start_date
    @event.start_time_in_user_tz = DateTime.parse("#{date} 12:00:00 pm").to_time(:utc)
    @event.end_time_in_user_tz   = @event.start_time_in_user_tz + 1.hour

    render :action => 'edit'
  end

  def import
    if uploaded_file = params[:icalendar]
      @calendar = nil
      if params[:calendar_type] == 'existing'
        @calendar = Calendar.find(params[:existing_calendar], :scope => :create_on)
      elsif params[:new_calendar]
        @calendar = current_user.calendars.create(:name => params[:new_calendar].strip, :parent_id => nil, :organization_id => current_organization.id)
      end
      
      if ! @calendar.blank?
        @calendar.add_and_save_events(Event.from_icalendar(uploaded_file.read))
        redirect_to calendar_month_route_url(:calendar_id => @calendar)
        return false
      else
        flash['error'] = _("An invalid calendar was chosen.")
      end
    end

    redirect_back_or_home
  rescue => e
    # Just created a new calendar which we need to destroy now
    logger.error "Exception occurred importing file #{e}"    
    @calendar.destroy if params[:calendar_type] == 'new' && !@calendar.blank? 
    @calendars = current_user.calendars(true)
    filename   = uploaded_file.original_filename rescue ''
    flash['error'] = _("There was a problem importing the iCalendar %{i18n_calendar_file}.  Please be sure that it is a valid file.")%{:i18n_calendar_file => "#{filename}"}

    redirect_back_or_home
  end

  def add_overlay
    if params[:user_id]
      session[:calendar] = {} unless session[:calendar]
      session[:calendar][:overlay_users] = [] unless session[:calendar][:overlay_users]
      session[:calendar][:overlay_users] = session[:calendar][:overlay_users].push(params[:user_id]).uniq.sort
    end
  ensure
    redirect_back_or_home
  end

  def remove_overlay
    if params[:user_id]
      session[:calendar] = {} unless session[:calendar]
      session[:calendar][:overlay_users] = [] unless session[:calendar][:overlay_users]
      session[:calendar][:overlay_users] = session[:calendar][:overlay_users].delete_if{|user| user == params[:user_id]}
    end
  ensure
    redirect_back_or_home
  end

  def create_calendar
    current_user.calendars.create(:name            => params[:group_name],
                                  :parent_id       => params[:parent_id],
                                  :organization_id => current_organization.id)
  ensure
    redirect_back_or_home
  end

  def delete
    if ! request.post? or params[:ids].blank?
      redirect_back_or_home and return
    end

    ids = params[:ids].split(',')
    deleted_events = []
    
    ids.each do |id|
      begin
        event = Event.find(id, :scope => :delete)
        event.destroy
        deleted_events << event
      rescue ActiveRecord::RecordNotFound
      end
    end

    respond_to do |wants|
      wants.html { redirect_back_or_home }
      wants.js   {
        render :update do |page|
          deleted_events.each do |event|
            page << "Item.removeFromList('#{event.dom_id}');"
          end
          page << 'JoyentPage.refresh()';
        end
      }
    end      
  end

  def item_delete_url
    calendar_event_delete_url
  end
  helper_method :item_delete_url 

  def item_move_url
    calendar_event_move_url
  end
  helper_method :item_move_url

  def item_copy_url
    calendar_event_copy_url
  end
  helper_method :item_copy_url

  def rename_group
    @calendar = Calendar.find(params[:id], :scope => :edit)
    @calendar.rename! params[:name]
  ensure
    redirect_back_or_home
  end

  def delete_group
    @calendar = Calendar.find(params[:id], :scope => :delete)
    @calendar.destroy

    redirect_to calendar_home_url
  end

  def reparent_group
    return unless params[:group_id]
    return unless params[:new_parent_id]

    return unless group = Calendar.find(params[:group_id], :scope => :move)
    return unless new_parent = Calendar.find(params[:new_parent_id], :scope => :create_on)
    group.reparent!(new_parent)
  ensure
    redirect_back_or_home
  end

  private
  
    def events_report(name, day_span)
      @view_kind = 'report'
      self.selected_user = User.find(params[:id], :scope => :read) if params.has_key?(:id)
      @group_name = name      
      @start_date = params['start_date'] ? Date.parse(params['start_date']) : current_user.today
      @end_date   = params['end_date']   ? Date.parse(params['end_date'])   : (@start_date + day_span)
      @events     = selected_user.calendars.collect{|c| current_user.can_view?(c) ? c.events_between(@start_date.to_time(:utc), @end_date.to_time(:utc)) : []}.flatten
      @day_views  = (@start_date...@end_date).collect do |curr_date| 
        view = DayView.new(curr_date)
        view.take_events(@events)
        view
      end  
   
      @toolbar[:list]   = false      
      @toolbar[:month]  = false    
      @toolbar[:today]  = false 
      @toolbar[:move]   = true
      @toolbar[:copy]   = true
      @toolbar[:delete] = true

      respond_to do |wants|
        wants.html { @view_kind = 'list'; render :action => 'list' }
        wants.js   { render :partial  => 'reports/events', 
                             :locals   => {:day_views => @day_views} }
      end
    end

    def setup_calendar
      session[:calendar] ||= {}
    end

    # load the overlay events as a hash keyed by user of their matching events
    def get_overlay_events(start_time, end_time)
      overlay_events = {}
      end_time = start_time + 1 if start_time == end_time

      # load up events to overlay if any users are specified
      if session[:calendar] and session[:calendar][:overlay_users]
        # get the events for each user for this date range
        session[:calendar][:overlay_users].each do |user_id|
          user = User.find(user_id, :scope => :read)
          overlay_events[user.id] = user.calendars.collect{|c| current_user.can_view?(c) ? c.events_between(start_time, end_time) : []}.flatten
        end
      end
    
      overlay_events
    end

    def setup_users_overlay
      @overlayed_users = if session[:calendar] and session[:calendar][:overlay_users]
        User.find(session[:calendar][:overlay_users], :include => [:person], :scope => :read).sort
      else
        []
      end
      @non_overlayed_users = (current_organization.users.find(:all, :conditions => ["guest = ?", false], :include => [:person], :scope => :read) - [current_user] - @overlayed_users).sort

      @toolbar[:overlay_users] = true

      true
    end

    def group_into_day_views(events, start_date, end_date)
      (start_date..end_date).collect do |curr_date| 
        view = DayView.new(curr_date)
        view.take_events(events)
        view
      end
    end

    def setup_toolbar
      super
      @toolbar[:new]    = true
      @toolbar[:new_on] = false
      @toolbar[:edit]   = false
      @toolbar[:move]   = false
      @toolbar[:copy]   = false
      @toolbar[:delete] = false
      @toolbar[:list]   = true
      @toolbar[:month]  = true
      @toolbar[:today]  = true
      @toolbar[:import] = true
      @toolbar[:overlay_users] = false
      true
    end
end