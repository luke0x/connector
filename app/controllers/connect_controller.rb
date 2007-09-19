=begin #(fold)
Copyright 2004-2007 Joyent Inc.

Redistribution and/or modification of this code is governed
by either the GPLv2 or Joyent Commercial Software licenses.

Report issues and contribute at http://dev.joyent.com/

$Id$
=end #(end)

class ConnectController < AuthenticatedController
  before_filter :load_sort_order, :only => [:list, :change_sort, :notifications, :smart_list, :current_time,
                                            :todays_events, :weeks_events, :recent_comments, :unread_messages]
#  after_filter(:only => [:save_search]){ |c| c.expire_fragment %r{connect/sidebar} }

  def current_group_id
    if    @smart_group then @smart_group.url_id
    elsif @group_name  then @group_name
    else  nil
    end
  end

  def index
    redirect_to reports_index_url
  end

  def notifications
    @view_kind = 'notifications'
    @toolbar[:import] = false
    notice_count = current_user.notifications_count(nil, params.has_key?(:all))
    @paginator = Paginator.new self, notice_count, JoyentConfig.page_limit, params[:page]

    if params.has_key?(:all)
      @group_name = _('All Notifications')
      @show_all = true
      @notifications = selected_user.notifications.find(:all, 
                                                        :include => {:notifier => [:person]},
                                                        :order   => "notifications.created_at DESC",
                                                        :limit   => @paginator.items_per_page, 
                                                        :offset  => @paginator.current.offset)
      @toolbar[:new_notifications] = true
    else
      @group_name = _('Notifications')
      @show_all = false
      @notifications = selected_user.current_notifications.find(:all,
                                                                :include => {:notifier => [:person]},
                                                                :order   => "notifications.created_at DESC",
                                                                :limit   => @paginator.items_per_page, 
                                                                :offset  => @paginator.current.offset)
      @toolbar[:all_notifications] = true
    end

    respond_to do |wants|
      wants.html { render :template => 'notifications/list' }
      wants.js   { render :partial  => 'reports/notifications', 
                          :locals   => {:show_all => @show_all} }
    end
  end

  def search
    @view_kind = 'list'
    @toolbar[:save_search] = true
    @group_name = _("Search: %{i18n_search_param}")%{:i18n_search_param => "'#{params[:search_string]}'"}

    @items = current_organization.search(params[:search_string])
    @paginator = Paginator.new self, @items.length, (@items.length > 0 ? @items.length : 1), 1

    render :action => 'list'
  end
  
  def save_search
    return if params[:search_string].blank?
    SmartGroup.create_from_search(params[:search_string])
  ensure
    redirect_back_or_home
  end

  def smart_list
    @view_kind    = 'list'
    @smart_group  = SmartGroup.find(SmartGroup.param_to_id(params[:smart_group_id]), :scope => :read)
    self.selected_user = @smart_group.owner
    @group_name   = @smart_group.name
    
    @paginator = Paginator.new self, @smart_group.items_count, JoyentConfig.page_limit, params[:page]
    @items     = @smart_group.items(nil, @paginator.items_per_page, @paginator.current.offset)
                            
    respond_to do |wants|
      wants.html { render :action  => 'list'  }
      wants.js   { render :partial => 'reports/items' }
    end
  rescue ActiveRecord::RecordNotFound
    redirect_to connect_home_url
  end

  def recent_comments
    @view_kind = 'report'
    @group_name   = 'Recent Comments'
    @comments     = Comment.find(:all, 
                                 :include    => 'user',
                                 :conditions => ['users.organization_id = ? AND created_at >= ?',
                                                 current_organization.id, Time.now - 7.days],
                                 :order      => 'created_at DESC')

    @comments = @comments.select{|comment| current_user.can_view?(comment.commentable)}
    @paginator = Paginator.new(self, @comments.size, JoyentConfig.page_limit, params[:page])
    @comments = @comments[@paginator.current_page.offset..@paginator.items_per_page] || []

    respond_to do |wants|
      wants.html
      wants.js   { render :partial => 'reports/comments' }
    end
  end                         

  def item_class_name
    nil
  end

  def lightning_portal
    @view_kind  = 'report'
    @group_name = 'Lightning Portal'
  end

  protected

    def setup_toolbar
      super
      @toolbar[:save_search] = false
      true
    end

end