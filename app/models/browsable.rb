=begin #(fold)
++
Copyright 2004-2007 Joyent Inc.

Redistribution and/or modification of this code is 
governed by the GPLv2.

Report issues and contribute at http://dev.joyent.com/

$Id$
--
=end #(end)

class Browsable
  attr_accessor :params, :current_user
  
  def initialize(params, current_user=nil)
    @params = params
    @current_user = User.find(params[:user_id]) rescue current_user
  end
  
  def items
    @items = []
    case @params[:type]
    when 'org'
      current_user.identity_other_users.each do |item|
        add_details( item.dom_id, 
                     "#{item.organization.name} - #{item.username}",
                     item.id,
                     @params[:app],
                     "UserShortcut",
                     @params[:app] ? 'group' : 'app',
                     @params[:subscribable_id] || nil,
                     @params[:subscribable_type] || nil )
      end
    when 'app'
      types = ['Mail', 'Calendar', 'People', 'Files', 'Bookmarks', 'Lists']
      apps = []
      types.each_index do |i|
        apps[i] = OpenStruct.new
        apps[i].app_name = types[i]
        apps[i].dom_id = "#{types[i].downcase}_"
        apps[i].id = i
      end
      @next_type = 'group'
      apps.each do |item|
        add_details( item.dom_id,
                     "#{item.app_name}",
                     @current_user.id,
                     @params[:app] ||= item.app_name,
                     @params[:app] ||= item.app_name,
                     'group' )
      end
    when 'group'
      user = User.find(@current_user)
      user.browser_root_groups_for(@params[:app].downcase).compact.each do |item|
        add_details( item.dom_id,
                     get_group_name(params[:app], item),
                     @current_user.id,
                     @params[:app],
                     @params[:app],
                     'view',
                     @params[:view] ? item.full_path : item.id,
                     item.class.to_s )
      end
    when 'view'
      if @params[:view] == 'StrongspaceFolder'
        items = [current_user.strongspace_folder]
        items.each do |item|
          add_details( item.dom_id,
                       get_group_name(@params[:app], item),
                       @current_user.id,
                       @params[:app],
                       @params[:app],
                       'view',
                       CGI::escape(item.id),
                       item.class.to_s )
        end
      else
        items = kids
        items.each do |item|
          add_details( item.dom_id,
                       get_group_name(@params[:app], item),
                       @current_user.id,
                       @params[:app],
                       @params[:app],
                       'view',
                       item.id,
                       item.class.to_s )
          end
      end
    end
    @items
  end
  
  def add_details(item_id, link_text, user_id, app_name, icon_class, next_type, subscription_id=nil, subscription_type=nil)
    item = OpenStruct.new
    item.dom_id = "browser_#{item_id}"
    item.link_text = link_text
    item.user_id = user_id
    item.app_name = app_name
    item.icon_class = icon_class
    item.next_type = next_type
    item.subscription_id = subscription_id
    item.subscription_type = subscription_type
    @items << item
  end
  
  def kids
    return [] if ['People', 'Bookmarks'].include?(@params[:app])
    
    group_type = @params[:view] ||= @params[:subscribable_type]
    path = @params[:subscribable_id] ||= ''
    
    if group_type == 'StrongspaceFolder'
      parent_group = StrongspaceFolder.find(current_user, @params[:subscribable_id], current_user)

      parent_group.children
    else
      parent_group = group_type(@params[:subscribable_type]).find(@params[:subscribable_id], :scope => :read)

      if parent_group.is_a?(Mailbox) && parent_group.full_name == 'INBOX'
        []
      elsif parent_group.is_a?(ListFolder) && parent_group.parent_id.blank?
        []
      else
        parent_group.children.find(:all, :scope => :read)
      end
    end
  end
  
  def group_type(type_name)
    valid_types = ['Mailbox', 'Calendar', 'ContactList', 'Folder', 'BookmarkFolder', 'ListFolder']
    raise "Unknown Group Type '#{type_name}'" unless valid_types.include?(type_name)

    Object.const_get(type_name)
  end
  
  def get_group_name(app, item)
    case app
    when 'Mail'      then item.name.downcase.capitalize
    when 'Calendar'  then item.name
    when 'Files'     then item.name
    when 'People'    then 'Contacts'
    when 'Bookmarks' then 'Bookmarks'
    when 'Lists'     then item.name
    end
  end
  
end