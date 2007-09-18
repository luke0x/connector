=begin #(fold)
Copyright 2004-2007 Joyent Inc.

Redistribution and/or modification of this code is governed
by either the GPLv2 or Joyent Commercial Software licenses.

Report issues and contribute at http://dev.joyent.com/

$Id$
=end #(end)

require 'digest/sha1'

class BookmarksController < AuthenticatedController
  before_filter :load_sort_order, :only => [:list, :list_everyone, :smart_list]

  # crud

  def index
    redirect_to bookmarks_list_route_url(:bookmark_folder_id => current_user.bookmark_folder.id)
  end

  def list
    @view_kind       = 'list'
    @bookmark_folder = BookmarkFolder.find(params[:bookmark_folder_id], :scope => :read)
    User.selected    = @bookmark_folder.owner
    @group_name      = _('Bookmarks')

    bookmark_count = Bookmark.restricted_count(:conditions => ['bookmark_folder_id = ?', @bookmark_folder.id])
    @paginator = Paginator.new(self, bookmark_count, JoyentConfig.page_limit, params[:page])
    @bookmarks = @bookmark_folder.bookmarks.find(:all, 
                                                 :order   => "LOWER(bookmarks.#{@sort_field}) #{@sort_order}",
                                                 :limit   => @paginator.items_per_page,
                                                 :offset  => @paginator.current.offset,
                                                 :include => [:owner, :permissions, :notifications, :taggings],
                                                 :scope   => :read)

    respond_to do |wants|
      wants.html { render :action  => 'list' }
      wants.js   { render :partial => 'reports/bookmarks' }
    end               
  rescue ActiveRecord::RecordNotFound
    redirect_to bookmarks_home_url
  end

  def list_everyone
    @view_kind     = 'list'
    @group_name    = _("Others' Bookmarks")
    bookmark_count = Bookmark.restricted_count(:conditions => ["bookmarks.user_id != ?", current_user.id])
    @paginator     = Paginator.new(self, bookmark_count, JoyentConfig.page_limit, params[:page])
    @bookmarks     = Organization.current.bookmarks.find(:all, 
                                                         :conditions => ["bookmarks.user_id != ?", current_user.id],
                                                         :order      => "LOWER(bookmarks.#{@sort_field}) #{@sort_order}",
                                                         :limit      => @paginator.items_per_page,
                                                         :offset     => @paginator.current.offset,
                                                         :include    => [:owner, :permissions, :notifications, :taggings], 
                                                         :scope      => :read)

    respond_to do |wants|
      wants.html { render :action  => 'list' }
      wants.js   { render :partial => 'reports/bookmarks' }
    end
  rescue ActiveRecord::RecordNotFound
    redirect_to bookmarks_home_url
  end

  def show
    @view_kind       = 'show'
    @bookmark        = Bookmark.find(params[:id], :scope => :read)
    User.selected    = @bookmark.owner
    @bookmark_folder = BookmarkFolder.find(@bookmark.bookmark_folder_id, :scope => :read)

    @toolbar[:edit] = true if current_user.can_edit?(@bookmark)

    respond_to do |wants|
      wants.html { render :action => 'show' }
      wants.js   { render :update do |page|
        page[params[:update_id]].replace_html :partial => 'peek'
      end }
    end
  rescue ActiveRecord::RecordNotFound
    redirect_to bookmarks_home_url
  end

  def create
    @toolbar[:copy]   = false
    @toolbar[:delete] = false

    # edit if this is already bookmarked
    unless params[:uri].blank?
      uri_sha1 = Digest::SHA1.hexdigest(params[:uri])
      if bookmark = current_user.bookmark_folder.bookmarks.find(:first, :conditions => ['uri_sha1 = ?', uri_sha1], :scope => :edit)
        redirect_to bookmarks_edit_route_url(:id => bookmark.id) and return
      end
    end

    if request.post?
      @bookmark = current_user.bookmark_folder.bookmarks.create(:user_id => current_user.id,
                                                                :organization_id => Organization.current.id,
                                                                :title => params[:title],
                                                                :notes => params[:notes],
                                                                :uri => params[:uri])

      params[:new_item_tags].split(',,').each do |tag_name|
        current_user.tag_item(@bookmark, tag_name)
      end unless params[:new_item_tags].blank?
      @bookmark.restrict_to!(current_user.bookmark_folder.users_with_permissions)
      # params[:new_item_permissions].split(',').each do |user_dom_id|
      #   next unless user = find_by_dom_id(user_dom_id)
      #   @bookmark.add_permission(user)
      # end unless params[:new_item_permissions].blank?
      params[:new_item_notifications].split(',').each do |user_dom_id|
        next unless user = find_by_dom_id(user_dom_id)
        user.notify_of(@bookmark, current_user)
      end unless params[:new_item_notifications].blank?

      if params[:via] == 'bookmarklet'
        redirect_to @bookmark.uri
      else
        redirect_to bookmarks_show_url(:id => @bookmark.id)
      end
    else
      @view_kind = 'create'
      @bookmark = Bookmark.new
      @bookmark.title = params[:title].to_s.strip
      @bookmark.uri = params[:uri].to_s.strip
      render :action => 'edit'
    end
  end

  def edit
    @view_kind = 'edit'
    @bookmark = Bookmark.find(params[:id], :scope => :edit)
    User.selected    = @bookmark.owner
    @bookmark_folder = BookmarkFolder.find(@bookmark.bookmark_folder_id, :scope => :read)
    @group_name      = _('Bookmarks')
    
    if request.post?
      @bookmark.title    = params[:title]
      @bookmark.uri      = params[:uri]
      @bookmark.notes    = params[:notes]
      @bookmark.save

      redirect_to bookmarks_show_url(:id => @bookmark.id)
      return true
    end
  rescue ActiveRecord::RecordNotFound
    redirect_to bookmarks_home_url
  end

  def delete
    if ! request.post? or params[:ids].blank?
      redirect_back_or_home and return
    end

    ids = params[:ids].split(',')
    deleted_bookmarks = []
    
    ids.each do |id|
      begin
        bookmark = Bookmark.find(id, :scope => :delete)
        bookmark.destroy
        deleted_bookmarks << bookmark
      rescue ActiveRecord::RecordNotFound
      end
    end

    respond_to do |wants|
      wants.html { redirect_back_or_home }
      wants.js   {
        render :update do |page|
          deleted_bookmarks.each do |bookmark|
            page << "Item.removeFromList('#{bookmark.dom_id}');"
          end
          page << 'JoyentPage.refresh()';
        end
      }
    end      
  end

  # extra joyent app actions

  def copy
    bookmarks = Bookmark.find(params[:ids].split(','), :scope => :copy)
    bookmarks.each do |bookmark|
      bookmark.copy_to(current_user.bookmark_folder)
    end
  ensure
    redirect_back_or_home
  end

  # belong elsewhere

  def notifications
    @view_kind = 'notifications'
    notice_count = current_user.notifications_count('Bookmark', params.has_key?(:all))
    @paginator = Paginator.new self, notice_count, JoyentConfig.page_limit, params[:page]

    @toolbar[:copy]   = false
    @toolbar[:delete] = false
    @toolbar[:bookmarklet] = false

    if params.has_key?(:all)
      @group_name = _('All Notifications')
      @show_all = true
      @notifications = current_user.notifications.find(:all, :conditions => ["notifications.item_type = 'Bookmark' "], :limit => @paginator.items_per_page, :offset => @paginator.current.offset)
      @toolbar[:new_notifications] = true
    else
      @group_name = _('Notifications')
      @show_all = false
      @notifications = current_user.current_notifications.find(:all, :conditions => ["notifications.item_type = 'Bookmark' "], :limit => @paginator.items_per_page, :offset => @paginator.current.offset)
      @toolbar[:all_notifications] = true
    end
    
    respond_to do |wants|
      wants.html { render :template => 'notifications/list'                         }
      wants.js   { render :partial  => 'reports/notifications', 
                          :locals   => {:show_all => @show_all} }  
    end    
  end

  def smart_list
    @view_kind    = 'list'
    @smart_group  = SmartGroup.find(SmartGroup.param_to_id(params[:smart_group_id]), :scope => :read)
    User.selected = @smart_group.owner
    @group_name   = @smart_group.name

    @paginator = Paginator.new(self, @smart_group.items_count, JoyentConfig.page_limit, params[:page])
    @bookmarks = @smart_group.items("bookmarks.#{@sort_field} #{@sort_order}", @paginator.items_per_page, @paginator.current.offset)

    respond_to do |wants|
      wants.html { render :action  => 'list' }
      wants.js   { render :partial => 'reports/bookmarks' }
    end
  rescue ActiveRecord::RecordNotFound
    redirect_to bookmarks_home_url
  end

  # legacy to get rid of soon

  def external_show
    redirect_to bookmarks_show_url(:id => params[:id])
  end

  def item_delete_url
    bookmarks_delete_url
  end
  helper_method :item_delete_url 

  def item_move_url
    bookmarks_move_url
  end
  helper_method :item_move_url

  def item_copy_url
    bookmarks_copy_url
  end
  helper_method :item_copy_url

  def self.group_name
    'Bookmark Folder'
  end

  def item_class_name
    'Bookmark'
  end

  private

    def setup_toolbar
      super
      @toolbar[:new]         = true
      @toolbar[:edit]        = false
      @toolbar[:copy]        = true
      @toolbar[:move]        = false
      @toolbar[:delete]      = true
      @toolbar[:sync]        = false
      @toolbar[:bookmarklet] = true
      true
    end

    def valid_sort_fields
      ['title', 'uri', 'created_at']
    end

    def default_sort_field
      'created_at'
    end

    def default_sort_order
      'DESC'
    end
  
end