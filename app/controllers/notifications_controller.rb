=begin #(fold)
Copyright 2004-2007 Joyent Inc.

Redistribution and/or modification of this code is governed
by either the GPLv2 or Joyent Commercial Software licenses.

Report issues and contribute at http://dev.joyent.com/

$Id$
=end #(end)

class NotificationsController < AuthenticatedController
  layout nil

  def create
    @user = User.find(params[:user_id], :scope => :read)
    return if @user.blank?
    page_js = []

    dom_ids = params[:dom_ids].split(',')
    dom_ids.each do |dom_id|
      next unless item = find_by_dom_id(dom_id)
      @user.active_notifications_for(item).map(&:acknowledge!) # only have 1 active notification at a time for now
      @user.notify_of(item, current_user)
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
          page << "Sidebar.Notify.refresh();"
        end
      }
    end
  rescue ActiveRecord::RecordNotFound
    render :nothing => true
  end

  def delete
    user = User.find(params[:user_id], :scope => :read)
    return if user.blank?
    page_js = []

    dom_ids = params[:dom_ids].split(',')
    dom_ids.each do |dom_id|
      next unless item = find_by_dom_id(dom_id)
      user.active_notifications_for(item).map(&:destroy)
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
          page << "Sidebar.Notify.refresh();"
        end
      }
    end
  rescue ActiveRecord::RecordNotFound
    render :nothing => true
  end

  def acknowledge
    notification = Notification.find(params[:id], :scope => :edit)
    notification.acknowledge!
    render :update do |page|
      page << "Notification.acknowledge('#{notification.dom_id}');"
    end
  rescue ActiveRecord::RecordNotFound
    render :text => TagController::ERROR_MSG
  end
end