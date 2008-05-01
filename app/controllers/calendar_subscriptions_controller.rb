=begin #(fold)
++
Copyright 2004-2007 Joyent Inc.

Redistribution and/or modification of this code is 
governed by the GPLv2.

Report issues and contribute at http://dev.joyent.com/

$Id$
--
=end #(end)

class CalendarSubscriptionsController < AuthenticatedController
  
  helper :calendar
  
  before_filter :setup_calendar
    
  def self.group_name
    'Calendar'
  end

  def item_class_name
    'Event'
  end
  
  def current_group_id
    if @group_name   then @group_name
    else  nil
    end
  end
  
  # REST
  
  # GET /calendar_subscriptions
  # GET /calendar_subscriptions.xml
  def index
    @calendar_subscriptions = CalendarSubscription.find(:all, :scope => :read)

    respond_to do |format|
      format.html { redirect_to calendar_home_url}
      format.xml  { render :xml => @calendar_subscriptions.to_xml }
    end
  end

  # GET /calendar_subscriptions/1
  # GET /calendar_subscriptions/1.xml
  def show
    @calendar_subscription = CalendarSubscription.find(params[:id], :scope => :read)

    respond_to do |format|
      format.html { redirect_to calendar_subscriptions_month_route_url(:calendar_subscription_id => @calendar_subscription.id)  }
      format.xml  { render :xml => @calendar_subscription.to_xml }
    end
  end

  # GET /calendar_subscriptions/new
  def new
    # Prevent problems with getto_urls and some REST actions
    @toolbar[:list] = false
    @toolbar[:month] = false
    
    @calendar_subscription = CalendarSubscription.new
    redirect_to calendar_home_url
  end

  # GET /calendar_subscriptions/1;edit
  def edit
    @calendar_subscription = CalendarSubscription.find(params[:id], :scope => :edit)
    self.selected_user = @calendar_subscription.owner
    
    redirect_to calendar_subscriptions_month_route_url(:calendar_subscription_id => @calendar_subscription.id)
  end

  # POST /calendar_subscriptions
  # POST /calendar_subscriptions.xml
  def create
    
    # Prevent problems with getto_urls and some REST actions
    @toolbar[:list] = false
    @toolbar[:month] = false
    
    calendar_subscription_params = params[:calendar_subscription].merge(:organization_id => current_user.organization.id, :user_id => current_user.id)
    @calendar_subscription = CalendarSubscription.new(calendar_subscription_params)
    
    respond_to do |format|
      if @calendar_subscription.save
        flash[:notice] = _('CalendarSubscription was successfully created.')
        format.html { redirect_to calendar_subscription_url(@calendar_subscription) }
        format.xml  { head :created, :location => calendar_subscription_url(@calendar_subscription) }
        format.js {
          render :update do |page|
            page.redirect_to calendar_subscription_url(@calendar_subscription)
          end
        }
      else
        format.html { 
          flash[:notice] = _('Cannot create Calendar ICS Subscription')
          redirect_back_or_home
        }
        format.xml  { render :xml => @calendar_subscription.errors.to_xml }
        format.js {
          render :update do |page|
            page.call("SubscriptionGroup.reEnableForm", 'NewICSSubscription')
            page['newICSSubscriptionLoading'].hide()
            page.alert(_('Cannot create Calendar ICS Subscription'))
            page['NewICSSubscription'].focus()
          end
        }
      end
    end
  rescue Exception => e
    respond_to do |format|
      flash[:notice] = e.message
      format.html { redirect_back_or_home }
      format.xml  { render :xml => "<errors><error>#{e.message}</error></errors>", :status => :unprocessable_entity }
      format.js   {
        render :update do |page|
          page.call("SubscriptionGroup.reEnableForm", 'NewICSSubscription')
          page['newICSSubscriptionLoading'].hide()
          page.alert(flash[:notice])
          page['NewICSSubscription'].focus()
        end
      }
    end
  end

  # PUT /calendar_subscriptions/1
  # PUT /calendar_subscriptions/1.xml
  def update
    @calendar_subscription = CalendarSubscription.find(params[:id], :scope => :edit)
    
    respond_to do |format|
      if @calendar_subscription.update_attributes(params[:calendar_subscription])
        flash[:notice] = _('Calendar ICS Subscription was successfully updated.')
        format.html { redirect_to calendar_subscription_url(@calendar_subscription) }
        format.xml  { head :ok }
      else
        format.html { 
          flash[:notice] = _('Cannot update Calendar ICS Subscription')
          redirect_back_or_home
        }
        format.xml  { render :xml => @calendar_subscription.errors.to_xml }
      end
    end
  rescue ActiveRecord::RecordNotFound
    redirect_to calendar_home_url
  end

  # DELETE /calendar_subscriptions/1
  # DELETE /calendar_subscriptions/1.xml
  def destroy
    @calendar_subscription = CalendarSubscription.find(params[:id], :scope => :delete)
    @calendar_subscription.destroy

    respond_to do |format|
      format.html { redirect_to calendar_home_url }
      format.xml  { head :ok }
    end
  rescue ActiveRecord::RecordNotFound
    redirect_to calendar_home_url    
  end
    
  # Calendar like
  
  def list
    @view_kind = 'list'
    @toolbar[:list] = false
    @start_date = params['start_date'] ? Date.parse(params['start_date']) : current_user.today
    @end_date   = params['end_date']   ? Date.parse(params['end_date'])   : (@start_date + 7)
    @paginator  = Paginator.new self, 1, JoyentConfig.page_limit, 1

    @calendar_subscription = CalendarSubscription.find(params[:calendar_subscription_id], :scope => :read)
    self.selected_user     = @calendar_subscription.owner
    @group_name       = @calendar_subscription.name
    @events           = @calendar_subscription.events_between(@start_date.to_time(:utc), @end_date.to_time(:utc))
    @day_views        = group_into_day_views(@events, @start_date, @end_date)

    @toolbar[:copy]   = current_user.can_copy_from?(@calendar_subscription)
    
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
    @month_view = MonthView.new(month_date, 0, current_user)

    @calendar_subscription = CalendarSubscription.find(params[:calendar_subscription_id], :scope => :read)
    self.selected_user     = @calendar_subscription.owner
    @group_name       = @calendar_subscription.name
    @events           = @calendar_subscription.events_between(@month_view.start_time, @month_view.end_time)
    @toolbar[:month]  = false
  
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
  
  # This one is like calendar_controller#show
  def show_event
    @view_kind = 'show'
    @calendar_subscription = CalendarSubscription.find(params[:id], :scope => :read)
    self.selected_user     = @calendar_subscription.owner
    @group_name       = @calendar_subscription.name
    @event            = @calendar_subscription.event_find(params[:event_id]) # TODO: get rid of this lameness
    @start_date       = @event.start_time_in_user_tz.to_date if @event
    @end_date         = @event.end_time_in_user_tz.to_date if @event
  
    @toolbar[:copy]   = current_user.can_copy?(@event)
  
    if @event
      respond_to do |wants|
        wants.html { render :action => 'show_event' }
        wants.js   { render :update do |page|
          page[params[:update_id]].replace_html :partial => 'calendar/peek'
        end }
      end
    else
      redirect_to calendar_home_url
    end
  rescue ActiveRecord::RecordNotFound
    redirect_to calendar_home_url
  end
  
  def refresh
    @calendar_subscription = CalendarSubscription.find(params[:calendar_subscription_id], :scope => :edit)
    
    respond_to do |format|
      if @calendar_subscription.refresh!
        flash[:notice] = _('Calendar ICS Subscription was successfully updated.')
        format.html { redirect_to calendar_subscription_url(@calendar_subscription) }
        format.js {
          render :update do |page|
            page.redirect_to calendar_subscription_url(@calendar_subscription)
          end
        }
      else
        flash[:notice] = _('Cannot update Calendar ICS Subscription')
        format.html { 
          redirect_to calendar_subscription_url(@calendar_subscription)
        }
        format.js {
          render :update do |page|
            page.alert("#{flash[:notice]}")
          end
        }
      end
    end
  rescue ActiveRecord::RecordNotFound
    redirect_to calendar_home_url
  # Any exception due to Net::HTTP or related
  rescue Exception => e
    respond_to do |format|
      flash[:notice] = e.message
      format.html { redirect_back_or_home }
      format.js   {
        render :update do |page|
          page.alert(flash[:notice])
        end
      }
    end
  end
  
  private

    def load_application
      @application_name = 'calendar'
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
          overlay_events[user.id].concat(user.calendar_subscriptions.collect{|cs| current_user.can_view?(cs) ? cs.events_between(start_time, end_time) : []}.flatten)
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
        view = DayView.new(curr_date, current_user)
        view.take_events(events)
        view
      end
    end
    
    def setup_toolbar
      super
      @toolbar[:new]    = false
      @toolbar[:new_on] = false
      @toolbar[:edit]   = false
      @toolbar[:move]   = false
      @toolbar[:copy]   = false
      @toolbar[:delete] = false
      @toolbar[:list]   = true
      @toolbar[:month]  = true
      @toolbar[:today]  = true
      @toolbar[:import] = false
      @toolbar[:overlay_users] = false
      true
    end
  
end
