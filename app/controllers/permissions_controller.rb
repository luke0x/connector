=begin #(fold)
Copyright 2004-2007 Joyent Inc.

Redistribution and/or modification of this code is governed
by either the GPLv2 or Joyent Commercial Software licenses.

Report issues and contribute at http://dev.joyent.com/

$Id$
=end #(end)

class PermissionsController < AuthenticatedController
  layout nil

#  after_filter :expire_sidebar, :only => [:set_group_permissions]

  def add_user
    user = User.find(params[:user_id], :scope => :read)
    return if user.blank?
    page_js = []

    dom_ids = params[:dom_ids].split(',')
    dom_ids.each do |dom_id|
      next unless item = find_by_dom_id(dom_id)
      item.add_permission(user)
      page_js << "Permission.findAllBy('itemDomId', '#{item.dom_id}').each(function(permission){ Permission.destroy(permission.domId); });"
      item.permissions(true).each do |permission|
        page_js << permission_to_jsar(permission)
      end unless item.public?
    end

    respond_to do |wants|
      wants.html { redirect_back_or_home }
      wants.js {
        render :update do |page|
          page << page_js.join("\n")
          page << "Sidebar.Access.refresh();"
          page << "Sidebar.Notify.refresh();"
        end
      }
    end      
  rescue ActiveRecord::RecordNotFound
    render :text => TagController::ERROR_MSG
  end

  def remove_user
    user = User.find(params[:user_id], :scope => :read)
    return if user.blank?
    page_js = []

    dom_ids = params[:dom_ids].split(',')
    dom_ids.each do |dom_id|
      next unless item = find_by_dom_id(dom_id)
      item.remove_permission(user)
      page_js << "Permission.findAllBy('itemDomId', '#{item.dom_id}').each(function(permission){ Permission.destroy(permission.domId); });"
      item.permissions(true).each do |permission|
        page_js << permission_to_jsar(permission)
      end unless item.public?
      page_js << "Notification.findAllBy('itemDomId', '#{item.dom_id}').each(function(notification){ Notification.destroy(notification.domId); });"
      item.active_notifications.each do |notification|
        page_js << notification_to_jsar(notification)
      end
    end

    respond_to do |wants|
      wants.html { redirect_back_or_home }
      wants.js {
        render :update do |page|
          page << page_js.join("\n")
          page << "Sidebar.Access.refresh();"
          page << "Sidebar.Notify.refresh();"
        end
      }
    end
  rescue ActiveRecord::RecordNotFound
    render :text => TagController::ERROR_MSG    
  end

  def make_public
    page_js = []

    dom_ids = params[:dom_ids].split(',')
    dom_ids.each do |dom_id|
      next unless item = find_by_dom_id(dom_id)
      item.make_public!
      page_js << "Permission.findAllBy('itemDomId', '#{item.dom_id}').each(function(permission){ Permission.destroy(permission.domId); });"
    end

    respond_to do |wants|
      wants.html { redirect_back_or_home }
      wants.js {
        render :update do |page|
          page << page_js.join("\n")
          page << "Sidebar.Access.refresh();"
          page << "Sidebar.Notify.refresh();"
        end
      }
    end
  rescue ActiveRecord::RecordNotFound
    render :text => TagController::ERROR_MSG    
  end

  def make_private
    page_js = []

    dom_ids = params[:dom_ids].split(',')
    dom_ids.each do |dom_id|
      next unless item = find_by_dom_id(dom_id)
      item.make_private!
      page_js << "Permission.findAllBy('itemDomId', '#{item.dom_id}').each(function(permission){ Permission.destroy(permission.domId); });"
      item.permissions(true).each do |permission|
        page_js << permission_to_jsar(permission)
      end
      page_js << "Notification.findAllBy('itemDomId', '#{item.dom_id}').each(function(notification){ Notification.destroy(notification.domId); });"
      item.active_notifications.each do |notification|
        page_js << notification_to_jsar(notification)
      end
    end

    respond_to do |wants|
      wants.html { redirect_back_or_home }
      wants.js {
        render :update do |page|
          page << page_js.join("\n")
          page << "Sidebar.Access.refresh();"
          page << "Sidebar.Notify.refresh();"
        end
      }
    end
  end
  
  def set_group_permissions
    group = group_type(params[:group_type]).find(params[:id], :scope => :edit)

    if params[:access_mode] == 'restricted'
      users = []
      if params.has_key?(:user_ids)
        users += [ User.find(params[:user_ids], :scope => :read) ].flatten
      end
      users << current_user unless users.include?(current_user)

      group.restrict_to!(users)
    elsif params[:access_mode] == 'public'
      group.make_public!
    end
  ensure
    redirect_back_or_home
  end
  
  private

    # def expire_sidebar
    #   case @group
    #   when Mailbox     then expire_fragment(%r{mail/sidebar})
    #   when Calendar    then expire_fragment(%r{calendar/sidebar})
    #   when ContactList then expire_fragment(%r{people/sidebar})
    #   when Folder      then expire_fragment(%r{files/sidebar})
    #   end
    # end
end