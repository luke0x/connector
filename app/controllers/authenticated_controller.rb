=begin #(fold)
Copyright 2004-2007 Joyent Inc.

Redistribution and/or modification of this code is governed
by either the GPLv2 or Joyent Commercial Software licenses.

Report issues and contribute at http://dev.joyent.com/

$Id$
=end #(end)

class AuthenticatedController < ApplicationController
  include GhettoUrls
  include JSAR

  before_filter :authkey_check
  before_filter :sso
  before_filter :ensure_user_loaded
  before_filter :verify_app_enabled
  before_filter :setup_vars,              :except => [:inbox_unread_count]
  before_filter :setup_toolbar,           :except => [:inbox_unread_count]
  before_filter :setup_calendar_overlays, :except => [:inbox_unread_count, :icon]
  before_filter :default_locale
  before_filter :subscription_check
  
  attr_accessor :is_subscription

#  cache_sweeper :user_sweeper

  def self.group_name
    'Group'
  end  
  
  def item_class_name
    nil
  end   
  
  def current_group_id
    nil  
  end

  # return a ul of children groups
  def children_groups
    parent_group  = group_type(self.class.group_name).find(params[:id], :scope => :read)
    self.selected_user = parent_group.owner
    children      = parent_group.children.find(:all, :scope => :read)

    render :partial => "sidebars/groups/children_groups", :locals => { :children => children }
  rescue ActiveRecord::RecordNotFound
    render :text => 'No children groups found'
  end

  def others_groups
    self.selected_user = User.find(params[:user_id], :scope => :read)
    render :partial => "sidebars/groups/#{@application_name}/others_#{@application_name}"
  end

  def set_sort_order
    sort_field = valid_sort_fields.include?(params[:sort_field]) ? params[:sort_field] : default_sort_field
    sort_order = [ 'ASC', 'DESC' ].include?(params[:sort_order]) ? params[:sort_order] : default_sort_order

    current_user.set_option("#{@application_name.capitalize} Sort Field", sort_field)
    current_user.set_option("#{@application_name.capitalize} Sort Order", sort_order)
  ensure
    redirect_back_or_home
  end

  # specify the home page for each app
  def home
    if request.env['REQUEST_PATH']
      request.env['REQUEST_PATH'].match(/home\/(.*)/)
      app_name = $1
    end

    redirect_to case app_name
    when 'connect'   then reports_index_url
    when 'mail'      then mail_special_list_url(:id => 'inbox')
    when 'calendar'  then calendar_all_month_url
    when 'people'    then people_list_url(:group => current_user.contact_list.id)
    when 'files'     then files_list_route_url(:folder_id => current_user.documents_folder.id)
    when 'bookmarks' then bookmarks_list_route_url(:bookmark_folder_id => current_user.bookmark_folder.id)
    when 'lists'     then lists_url(:group => current_user.lists_list_folder.id)
    when 'fileswpl'  then files_service_url(:service_name => 'lightning', :group_id => nil)
    when 'wpl'       then files_service_url(:service_name => 'lightning', :group_id => nil)
    else 
      reports_index_url
    end
  end

  private
  
    def load_sort_order
      @sort_field = current_user.get_option("#{@application_name.capitalize} Sort Field") || default_sort_field
      @sort_order = current_user.get_option("#{@application_name.capitalize} Sort Order") || default_sort_order
    end

    def default_sort_field
      nil
    end

    def default_sort_order
      nil
    end

    def setup_vars
      @page_javascript = []
      @smart_groups    = current_user.application_smart_groups(@application_name)
      true
    end                     
  
    def setup_toolbar
      @toolbar = {}
    end
    
    def authkey_check
      if params[:authkey] && (key = AuthKey.verify(params[:authkey], current_organization))
        User.current               = key.user
        session[:sso_verified]     = true
        LoginToken.current         = current_user.create_login_token
        cookies['sso_token_value'] = {:value => LoginToken.current.value, :expires => Time.now + 2.weeks}
        key.destroy
        
        redirect_to request.env['REQUEST_PATH']
        return false
      end
    end
  
    def sso
      # first see if already logged in
      if session[:sso_verified] and request.cookies['sso_token_value'] and LoginToken.current = LoginToken.find_by_value(request.cookies['sso_token_value'])
        User.current = current_organization.users.find(LoginToken.current.user_id, :include => [:user_options])
      # now see if they have a remember cookie
      elsif request.cookies['sso_remember'] and request.cookies['sso_remember'][0] == 'true' and request.cookies['sso_token_value'] and LoginToken.current = LoginToken.find_for_cookie(request.cookies['sso_token_value'][0])
        session[:sso_verified] = true
        User.current = current_organization.users.find(LoginToken.current.user_id)
      # remember the page and let them log in
      else
        session[:post_login_url] = request.env['REQUEST_URI']
        redirect_to login_url and return false
      end
    rescue ActiveRecord::RecordNotFound
      redirect_to logout_url and return false
    end

    # NOTE: quite a few exception emails seem to be due to calling methods on a nil current_user, which should never
    # happen. i think this is due to proxy errors, but it's hard to say. since, within the app, it should be safe
    # to assume current_user is set, i'd like to try catching this problem earlier + specifically for a while.
    def ensure_user_loaded
      raise "Current user nil" if current_user.blank?
      raise "Current user not class User" unless current_user.is_a?(User)
      true
    end

    def verify_app_enabled
      if current_user.guest?
        redirect_to files_strongspace_url and return false
      else
        true
      end
    end
  
    def setup_calendar_overlays
      # always clear when leaving the calendar app
      if @application_name != "calendar" and session[:calendar]
        session[:calendar] = nil
      end
    
      true
    end

    def item_type(type_name)
      valid_types = ['Message', 'Event', 'Person', 'JoyentFile', 'Bookmark', 'List', 'User']
      raise 'Unknown Item Type' unless valid_types.include?(type_name)

      Object.const_get(type_name)
    end

    # TODO: make sure this is always called expecting :scope => :read
    def find_by_dom_id(dom_id)
      dom_id = dom_id.split('_')
      klass = item_type(dom_id[0..-2].collect(&:capitalize).join)
      item_id = dom_id[-1]
    
      klass.find(item_id, :scope => :read)
    rescue
      nil
    end

    def group_type(type_name)
      valid_types = ['Mailbox', 'Calendar', 'ContactList', 'Folder', 'BookmarkFolder', 'ListFolder']
      raise "Unknown Group Type '#{type_name}'" unless valid_types.include?(type_name)

      Object.const_get(type_name)
    end

    def default_locale
      GetText.locale = current_user.language
      Date.translate_strings
      GetText.locale
    end
    
    def subscription_check
      case self.controller_name
        when 'mail'
          subscribed_by_action(['list'], 'Mailbox', self.params[:id])
        when 'calendar'
          subscribed_by_action(['list', 'month', 'day'], 'Calendar', self.params[:calendar_id])
        when 'people'
          subscribed_by_action(['list'], 'ContactList', self.params[:group])
        when 'files'
          subscribed_by_action(['list'], 'Folder', self.params[:folder_id])
        when 'bookmarks'
          subscribed_by_action(['list'], 'BookmarkFolder', self.params[:bookmark_folder_id])
        when 'lists'
          subscribed_by_action(['index'], 'ListFolder', self.params[:group])
        end
    end
    
    def subscribed_by_action(list, name, id)
      if list.include? self.action_name
        @is_subscription = current_user.subscribed_to?(nil, name, id.to_i)
      end
      true
    end
end