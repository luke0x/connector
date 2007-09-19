=begin #(fold)
Copyright 2004-2007 Joyent Inc.

Redistribution and/or modification of this code is governed
by either the GPLv2 or Joyent Commercial Software licenses.

Report issues and contribute at http://dev.joyent.com/

$Id$
=end #(end)

class FilesController < AuthenticatedController  
  helper :people

  before_filter :load_sort_order, :only => [:list, :smart_list]
#  after_filter(:only => [:create_folder, :rename_group, :delete_group, :reparent_group]){ |c| c.expire_fragment %r{files/sidebar} }

  def current_group_id
    if    @smart_group then @smart_group.url_id
    elsif @folder      then @folder.id
    elsif @group_name  then @group_name
    else  nil
    end
  end

  def index
    redirect_to files_list_route_url(:folder_id => User.current.documents_folder.id)
  end

  def list
    @view_kind    = 'list'
    @folder       = Folder.find(params[:folder_id], :scope => :read)
    User.selected = @folder.owner
    @group_name   = @folder.name
    file_count    = JoyentFile.restricted_count(:conditions => ['folder_id = ?', @folder.id])
    @paginator    = Paginator.new self, file_count, JoyentConfig.page_limit, params[:page]
    @files        = @folder.joyent_files.find(:all, 
                                              :order      => "LOWER(joyent_files.#{@sort_field}) #{@sort_order}",
                                              :limit      => @paginator.items_per_page,
                                              :offset     => @paginator.current.offset,
                                              :include    => [:owner, :permissions, :notifications, :taggings],
                                              :scope      => :read)

    @toolbar[:move]   = User.current.can_move_from?(@folder)
    @toolbar[:copy]   = User.current.can_copy_from?(@folder)
    @toolbar[:email]  = User.current.can_email_from?(@folder)
    @toolbar[:delete] = User.current.can_delete_from?(@folder)
         
    respond_to do |wants|
      wants.html
      wants.js   { render :partial => 'reports/files' }
    end
  rescue ActiveRecord::RecordNotFound
    redirect_to files_home_url
  end

  def move 
    file_ids   = params[:ids].split(',')
    new_folder = Folder.find(params[:new_group_id], :scope => :create_on)
            
    if file_ids && new_folder
      file_ids.each do |file_id|
        if file = JoyentFile.find(file_id, :scope => :move)
          file.move_to(new_folder)
        end
      end 
    end 
  ensure
    redirect_back_or_home
  end     

  def copy
    file_ids   = params[:ids].split(',')
    new_folder = Folder.find(params[:new_group_id], :scope => :create_on)

    if file_ids && new_folder    
      file_ids.each do |file_id|
        if file = JoyentFile.find(file_id, :scope => :copy)
          file.copy_to(new_folder)
        end
      end
    end  
  ensure
    redirect_back_or_home
  end
  
  def show
    @view_kind = 'show'
    if params[:folder_id]
      @folder       = Folder.find(params[:folder_id], :scope => :read)
      User.selected = @folder.owner
      @file         = @folder.joyent_files.find(params[:id], :scope => :read)
      @group_name   = @folder.name

      @toolbar[:edit]   = User.current.can_edit?(@file)
      @toolbar[:move]   = User.current.can_move?(@file)
      @toolbar[:copy]   = User.current.can_copy?(@file)
      @toolbar[:email]  = User.current.can_email?(@file)
      @toolbar[:delete] = User.current.can_delete?(@file)
    else
      @file         = JoyentFile.find(params[:id], :scope => :read)
      User.selected = @file.owner
      @folder       = @file.folder
      @group_name   = @folder.name
    end
    
    if @file
      respond_to do |wants|
        wants.html { render :action => 'show' }
        wants.js   { render :update do |page|
          page[params[:update_id]].replace_html :partial => 'peek'
        end }
      end
    else
      redirect_to files_home_url
    end
  rescue ActiveRecord::RecordNotFound
    redirect_to files_home_url
  end  
  
  def external_show
    @file   = JoyentFile.find(params[:id], :scope => :read)
    @folder = @file.folder
    redirect_to files_show_route_url(:folder_id => @folder, :id => @file)
  end

  def edit
    @view_kind    = 'edit'
    @folder       = Folder.find(params[:folder_id], :scope => :read)
    User.selected = @folder.owner
    @file         = @folder.joyent_files.find(params[:id], :scope => :edit)
    @group_name   = @folder.name

    @toolbar[:move]   = User.current.can_move?(@file)
    @toolbar[:copy]   = User.current.can_copy?(@file)
    @toolbar[:email]  = User.current.can_email?(@file)
    @toolbar[:delete] = User.current.can_delete?(@file)

    if request.post? and params[:file]
      @file.notes = params[:file][:notes]
      @file.rename_without_extension! params[:file][:name]
      redirect_to files_show_route_url(:id => @file.id)
      return true
    end
  rescue ActiveRecord::RecordNotFound
    redirect_to files_home_url
  end

  def delete
    if ! request.post? or params[:ids].blank?
      redirect_back_or_home and return
    end

    ids = params[:ids].split(',')
    deleted_files = []

    ids.each do |id|
      begin
        file = JoyentFile.find(id, :scope => :delete)
        file.remove!
        deleted_files << file
      rescue ActiveRecord::RecordNotFound
      end
    end

    respond_to do |wants|
      wants.html { redirect_back_or_home }
      wants.js   {
        render :update do |page|
          deleted_files.each do |file|
            page << "Item.removeFromList('#{file.dom_id}');"
          end
          page << 'JoyentPage.refresh()';
        end
      }
    end
  end

  def notifications
    @view_kind = 'notifications'
    notice_count = User.current.notifications_count('JoyentFile', params.has_key?(:all))
    @paginator = Paginator.new self, notice_count, JoyentConfig.page_limit, params[:page]

    if params.has_key?(:all)
      @group_name = _('All Notifications')
      @show_all = true
      @notifications = User.selected.notifications.find(:all, 
                                                        :conditions => ["notifications.item_type = 'JoyentFile' "],
                                                        :include    => {:notifier => [:person]},
                                                        :order      => "notifications.created_at DESC",
                                                        :limit      => @paginator.items_per_page, 
                                                        :offset     => @paginator.current.offset)
      @toolbar[:new_notifications] = true
    else
      @group_name = _('Notifications')
      @show_all = false
      @notifications = User.selected.current_notifications.find(:all, 
                                                                :conditions => ["notifications.item_type = 'JoyentFile' "], 
                                                                :include    => {:notifier => [:person]},
                                                                :order      => "notifications.created_at DESC",
                                                                :limit      => @paginator.items_per_page, 
                                                                :offset     => @paginator.current.offset)
      @toolbar[:all_notifications] = true
    end

    respond_to do |wants|
      wants.html { render :template => 'notifications/list'     }
      wants.js   { render :partial  => 'reports/notifications', 
                          :locals   => {:show_all => @show_all} }  
    end  
  end

  def smart_list
    @view_kind    = 'list'
    @smart_group  = SmartGroup.find(SmartGroup.param_to_id(params[:smart_group_id]), :scope => :read)
    User.selected = @smart_group.owner
    @group_name   = @smart_group.name

    @paginator = Paginator.new self, @smart_group.items_count, JoyentConfig.page_limit, params[:page]
    @files     = @smart_group.items("joyent_files.#{@sort_field} #{@sort_order}", @paginator.items_per_page, @paginator.current.offset)
     
    # It appears that the pagination doesn't do much, so lets page now - PDI
    @files         = @files[@paginator.current.offset, @paginator.items_per_page]

    @toolbar[:move]   = User.current.can_move_from?(@smart_group)
    @toolbar[:copy]   = User.current.can_copy_from?(@smart_group)
    @toolbar[:email]  = User.current.can_email_from?(@smart_group)
    @toolbar[:delete] = User.current.can_delete_from?(@smart_group)
 
    respond_to do |wants|
      wants.html { render :action  => 'list'  }
      wants.js   { render :partial => 'reports/files' }  
    end
  rescue ActiveRecord::RecordNotFound
    redirect_to files_home_url
  end

  def smart_show 
    @view_kind   = 'show'
    @smart_group = SmartGroup.find(SmartGroup.param_to_id(params[:smart_group_id]), :scope => :read)
    @group_name  = @smart_group.name
    @file        = JoyentFile.find(params[:id], :scope => :read)

    @toolbar[:edit]   = User.current.can_edit?(@file)
    @toolbar[:move]   = User.current.can_move?(@file)
    @toolbar[:copy]   = User.current.can_copy?(@file)
    @toolbar[:email]  = User.current.can_email?(@file)
    @toolbar[:delete] = User.current.can_delete?(@file)

    respond_to do |wants|
      wants.html { render :action => 'show' }
      wants.js   { render :update do |page|
        page[params[:update_id]].replace_html :partial => 'peek'
      end }
    end
    rescue ActiveRecord::RecordNotFound
      redirect_to files_home_url
  end

  def smart_edit 
    @view_kind   = 'edit'
    @smart_group = SmartGroup.find(SmartGroup.param_to_id(params[:smart_group_id]), :scope => :read)
    @group_name  = @smart_group.name  
    @file        = JoyentFile.find(params[:id], :scope => :edit)
    
    @toolbar[:move]   = User.current.can_move?(@file)
    @toolbar[:copy]   = User.current.can_copy?(@file)
    @toolbar[:email]  = User.current.can_email?(@file)
    @toolbar[:delete] = User.current.can_delete?(@file)
    
    if request.post? and params[:file]
      @file.notes = params[:file][:notes]
      @file.rename_without_extension! params[:file][:name]
      redirect_to files_show_url(:id => @file.id)
      return true 
    end           
    render :action  => 'edit'
  rescue ActiveRecord::RecordNotFound
    redirect_to files_home_url
  end

  def download
    @joyent_file = JoyentFile.find(params[:id], :scope => :read)
    send_joyent_file(@joyent_file, true)
#    render :nothing => true
  rescue ActiveRecord::RecordNotFound
    redirect_to files_home_url
  end

  def download_inline
    @joyent_file = JoyentFile.find(params[:id], :scope => :read)
    send_joyent_file(@joyent_file, false)
#    render :nothing => true
  rescue ActiveRecord::RecordNotFound
    redirect_to files_home_url
  end

  def create
    @view_kind = 'create'
    begin
      @folder = Folder.find(params[:folder_id], :scope => :create_on)
    rescue ActiveRecord::RecordNotFound
      @folder = User.current.documents_folder
    end
    @group_name = @folder.name

    if request.post?
      5.times do |i|
        next unless uploaded_file = params["upload_#{i}"]
        next if uploaded_file.blank?
        next if uploaded_file.original_filename.blank?

        Folder.transaction do
          @file = @folder.add_file(uploaded_file)

          params[:new_item_tags].split(',,').each do |tag_name|
            User.current.tag_item(@file, tag_name)
          end unless params[:new_item_tags].blank?
          params[:new_item_permissions].split(',').each do |user_dom_id|
            next unless user = find_by_dom_id(user_dom_id)
            @file.add_permission(user)
          end unless params[:new_item_permissions].blank?
          params[:new_item_notifications].split(',').each do |user_dom_id|
            next unless user = find_by_dom_id(user_dom_id)
            user.notify_of(@file, User.current)
          end unless params[:new_item_notifications].blank?
        end
      end

      redirect_to files_list_route_url(:folder_id => @folder.id)
    else
      @file = JoyentFile.new

      @toolbar[:new] = false
    end
  rescue ActiveRecord::RecordNotFound
    redirect_to files_home_url
  end

  def create_folder
    if params[:parent_path]
      StrongspaceFolder.create(User.current, File.join(params[:parent_path], params[:group_name]))
    else
      parent_id = (params[:parent_id] == User.current.files_documents_folder.id.to_s) ? nil : params[:parent_id]
      User.current.folders.create(:name            => params[:group_name],
                                  :parent_id       => parent_id,
                                  :organization_id => Organization.current.id)
    end
  ensure
    redirect_back_or_home
  end

  def browser
    begin
      @folder   = Folder.find(params[:folder_id], :scope => :read)
      @children = @folder.children
      @files    = @folder.joyent_files
    rescue ActiveRecord::RecordNotFound
      @folder   = nil
      @children = User.current.folders.find(:all, :conditions => ["folders.parent_id IS NULL"], :scope => :read)
      @files    = []
    end

    render :layout => false
  end

  def rename_group
    @folder = Folder.find(params[:id], :scope => :edit)
    @folder.rename! params[:name]
  ensure
    redirect_back_or_home
  end
  
  def delete_group
    @folder = Folder.find(params[:id], :scope => :delete)
    @folder.destroy
    redirect_to files_home_url
  end

  def self.group_name
    'Folder'
  end
  
  def item_class_name
    'JoyentFile'
  end

  def item_delete_url
    @view_kind == 'strongspace' ? files_strongspace_delete_url : files_delete_url
  end
  helper_method :item_delete_url
                                      
  def item_move_url
    @view_kind == 'strongspace' ? files_strongspace_move_url : files_move_url
  end
  helper_method :item_move_url
  
  def item_copy_url
    @view_kind == 'strongspace' ? files_strongspace_copy_url : files_copy_url
  end
  helper_method :item_copy_url        

  def setup_toolbar
    super       
    @toolbar[:quota]  = true
    @toolbar[:new]    = true
    @toolbar[:edit]   = false
    @toolbar[:move]   = false
    @toolbar[:copy]   = false
    @toolbar[:email]  = false
    @toolbar[:delete] = false   
    true
  end

  def reparent_group
    return unless params[:group_id]
    return unless params[:new_parent_id]

    group = Folder.find(params[:group_id], :scope => :move)
    return unless group

    new_parent = Folder.find(params[:new_parent_id], :scope => :create_on)

    group.reparent!(new_parent)
  ensure
    redirect_back_or_home
  end


  # sftp actions


    def strongspace_children_groups
      @view_kind = 'strongspace'
      parent_group  = StrongspaceFolder.find(User.current, params[:path], User.current)
      User.selected = parent_group.owner
      children      = parent_group.children

      render :partial => "sidebars/groups/strongspace_children_groups", :locals => { :children => children }
    rescue
      render :text => 'No children groups found'
    end

    def set_guest_access
      folder = StrongspaceFolder.find(User.current, params[:path], User.current)

      if params[:access_mode] == 'guests_restricted'
        folder.remove_guest_access!
      elsif params[:access_mode] == 'guests_allowed'
        folder.remove_guest_access!

        params[:user_ids].each do |user_id|
          folder.grant_guest_access(User.find(user_id, :scope => :read))
        end
      end
    ensure
      redirect_back_or_home
    end

    def strongspace_move 
      @view_kind = 'strongspace'
      paths      = params[:ids].split(',')
      new_folder = StrongspaceFolder.find(User.current, params[:new_group_id], User.current)

      paths.each do |path|
        begin
          file = StrongspaceFile.find(User.current, path, User.current)
          file.move_to(new_folder)
        rescue StrongspaceFile::FileNotFound
        end
      end
    ensure
      redirect_back_or_home
    end

    def strongspace_copy
      @view_kind = 'strongspace'
      paths      = params[:ids].split(',')
      new_folder = StrongspaceFolder.find(User.current, params[:new_group_id], User.current)

      paths.each do |path|
        begin
          file = StrongspaceFile.find(User.current, path, User.current)
          file.copy_to(new_folder)
        rescue StrongspaceFile::FileNotFound
        end
      end
    ensure
      redirect_back_or_home
    end

    def strongspace_show
      @view_kind = 'strongspace'

      owner = Organization.current.users.find(params[:owner_id])
      @file = StrongspaceFile.find(owner, params[:path], User.current)
      User.selected = @file.owner
      @folder = StrongspaceFolder.find(owner, params[:path][0..-2], User.current)
      @group_name = @folder.name

      @toolbar[:edit]   = User.current.owns?(@file)
      @toolbar[:move]   = User.current.can_move?(@file)
      @toolbar[:copy]   = User.current.can_move?(@file) # use for copy, since can_copy? relies on permissions
      @toolbar[:email]  = User.current.can_email?(@file)
      @toolbar[:delete] = User.current.can_delete?(@file)

      respond_to do |wants|
        wants.html { render :action => 'strongspace_show' }
        wants.js   { render :update do |page|
          page[params[:update_id]].replace_html :partial => 'strongspace_peek'
        end }
      end
    rescue Errno::ENOENT
      redirect_to files_strongspace_url(:owner_id => User.current.id)
    end  

    def strongspace_delete
      @view_kind = 'strongspace'
      paths = params[:ids].split(',')
      deleted_files = []

      paths.each do |path|
        begin
          file = StrongspaceFile.find(User.current, path, User.current)
          file.remove!
          deleted_files << file
        rescue StrongspaceFile::FileNotFound
        end
      end

      respond_to do |wants|
        wants.html { redirect_back_or_home }
        wants.js   {
          render :update do |page|
            deleted_files.each do |file|
              page << "Item.removeFromList('#{file.dom_id}');"
            end
            page << 'JoyentPage.refresh()';
          end
        }
      end      
    end  

    def strongspace
      @view_kind    = 'strongspace'

      if !User.current.guest? && params[:owner_id].nil?
        params[:owner_id] = User.current.id
      end

      if params[:owner_id]
        owner         = Organization.current.users.find(params[:owner_id])
        @folder       = StrongspaceFolder.find(owner, params[:path] || '', User.current)
        User.selected = @folder.owner
        @files        = @folder.files
        file_count    = @folder.children.size
        @group_name   = @folder.name
      elsif User.current.guest?
        @folder       = StrongspaceFolder.blank
        User.selected = User.current
        @files        = []
        @file_count   = 0
        @group_name   = _('Strongspace')
      else
        # TODO: should this block execute ?
        @folder       = StrongspaceFolder.new(User.current, '')
        User.selected = User.current
        @files        = []
        file_count    = 0
        @group_name   = _('Strongspace')
      end

      @paginator = Paginator.new self, file_count, JoyentConfig.page_limit, params[:page]

      @toolbar[:new]    = User.current.can_create_on?(@folder)
      @toolbar[:move]   = User.current.can_move_from?(@folder)
      @toolbar[:copy]   = User.current.can_copy_from?(@folder)
      @toolbar[:email]  = User.current.can_email_from?(@folder)
      @toolbar[:delete] = User.current.can_delete_from?(@folder)

      respond_to do |wants|
        wants.html
        wants.js   { render :partial => 'reports/strongspace_files' }
      end
    end

    def strongspace_download
      @view_kind = 'strongspace'
      owner = Organization.current.users.find(params[:owner_id])
      @joyent_file = StrongspaceFile.find(owner, params[:path], User.current)
      send_joyent_file @joyent_file, true
  #    render :nothing => true
    end

    def strongspace_download_inline
      @view_kind = 'strongspace'
      owner = Organization.current.users.find(params[:owner_id])
      @joyent_file = StrongspaceFile.find(owner, params[:path], User.current)
      send_joyent_file(@joyent_file, false)
  #    render :nothing => true
    rescue
      redirect_to files_home_url
    end

    def strongspace_create
      @view_kind = 'strongspace'
      begin
        @folder = StrongspaceFolder.find(User.current, params[:path], User.current)
      rescue
        @folder = User.current.strongspace_folder
      end
      @group_name = @folder.name

      if request.post?
        5.times do |i|
          next unless uploaded_file = params["upload_#{i}"]
          next if uploaded_file.blank?
          next if uploaded_file.original_filename.blank?

          @file = @folder.add_file(uploaded_file)
        end

        redirect_to files_strongspace_list_url(:owner_id => @folder.owner.id, :path => @folder.relative_path)
      else
        @file = JoyentFile.new # not really a 'joyent file' but w/e

        @toolbar[:new] = false
      end
    rescue ActiveRecord::RecordNotFound
      redirect_to files_home_url
    end

    def rename_strongspace_group
      @folder = StrongspaceFolder.find(User.current, params[:path], User.current)
      @folder.rename! params[:name]
    ensure
      redirect_to files_strongspace_list_url(:owner_id => @folder.owner.id, :path => @folder.relative_path)
    end

    def delete_strongspace_group
      @folder = StrongspaceFolder.find(User.current, params[:path], User.current)
      @folder.destroy
      redirect_to files_home_url
    end

    def reparent_strongspace_group
      return unless params[:path]
      return unless params[:new_parent_path]

      group = StrongspaceFolder.find(User.current, params[:path], User.current)
      return unless group

      new_parent = StrongspaceFolder.find(User.current, params[:new_parent_path], User.current)

      group.reparent!(new_parent)
    ensure
      redirect_to files_strongspace_url
    end


    # lightning actions

    
    def service
      @view_kind    = 'service'
      @service      = Service.find(params[:service_name], User.current)

      unless @service
        redirect_to files_home_url 
        return
      end

      User.selected = @service.owner    
      @folder       = @service.find_folder(params[:group_id])
      unless @folder
        redirect_to files_home_url
        return
      end
      @folder     ||= @service.root_folder
      @group_name   = @folder.name
      @files        = @folder.files
      @paginator    = Paginator.new self, @files.size, JoyentConfig.page_limit, params[:page]

      # TODO what are we doing about these?
      @toolbar[:new] = false
      # @toolbar[:move]   = User.current.can_move_from?(@folder)
      # @toolbar[:copy]   = User.current.can_copy_from?(@folder)
      @toolbar[:email]  = User.current.can_email_from?(@folder)
      # @toolbar[:delete] = User.current.can_delete_from?(@folder)

      respond_to do |wants|
        wants.html
        wants.js   { render :partial => 'reports/service_files' }
      end
    end

    def service_show
      @view_kind = 'service'
      @service    = Service.find(params[:service_name], User.current)

      unless @service
        redirect_to files_home_url 
        return
      end

      @file       = @service.find_file(params[:file_id])  
      @folder     = @file.folder  
      @group_name = @folder.name

      # TODO what are we doing about these?
      @toolbar[:new] = false
      # @toolbar[:move]   = User.current.can_move_from?(@folder)
      # @toolbar[:copy]   = User.current.can_copy_from?(@folder)
      @toolbar[:email]  = User.current.can_email?(@file)
      # @toolbar[:delete] = User.current.can_delete_from?(@folder)

      respond_to do |wants|
        wants.html
        wants.js   { render :update do |page|
                       page[params[:update_id]].replace_html :partial => 'service_peek'
                     end 
                   }
      end
    end

    def service_download
      @service     = Service.find(params[:service_name], User.current)
      @joyent_file = @service.find_file(params[:file_id])
      send_joyent_file @joyent_file, true
  #    render :nothing => true    
    end

    def service_download_inline
      @service     = Service.find(params[:service_name], User.current)
      @joyent_file = @service.find_file(params[:file_id])

      if @joyent_file
        send_joyent_file(@joyent_file, false)
        session[:last_inline_service_file_id] = params[:file_id]
        return
      else
        # perhaps the file exists on the disk b/c it is referenced from another file
        file_path = File.join(@service.root_path, params[:file_id])

        if session[:last_inline_service_file_id]
          # First determine what the last file was, so we can have a reference to the proper directory
          # in case this file exists in there
          joyent_file = @service.find_file(session[:last_inline_service_file_id])

          possible_path = File.join(File.dirname(joyent_file.path_on_disk), params[:file_id]) if joyent_file

          file_path = possible_path if possible_path && MockFS.file.exist?(possible_path)
        end

        if MockFS.file.exist?(file_path)
          send_file file_path, :disposition => 'inline'
          return
        end
      end

     render :nothing => true
    rescue
      redirect_to files_home_url
    end

    def service_children_groups
      @service      = Service.find(params[:service_name], User.current)
      parent_group  = @service.find_folder(params[:group_id])
      User.selected = parent_group.owner
      children      = parent_group.children

      render :partial => "sidebars/groups/service_children_groups", :locals => { :children => children }
    rescue
      render :text => 'No children groups found'
    end

  private
  
    def verify_app_enabled
      # TODO: needs different actions based on rw ability
      strongspace_actions = ['strongspace', 'strongspace_children_groups', 'strongspace_download', 'strongspace_download_inline', 'strongspace_show']

      if User.current.guest?
        if strongspace_actions.include?(action_name)
          true
        else
          redirect_to files_strongspace_url and return false
        end
      else
        true
      end
    end
  
    def valid_sort_fields
      ['filename', 'size_in_bytes', 'updated_at', 'joyent_file_type_description']
    end

    def default_sort_field
      'filename'
    end

    def default_sort_order
      'ASC'
    end
  
    ## Our own send file which plugs in to mongrel
    def send_joyent_file(joyent_file, attachment)
      # fts = OpenStruct.new
      # fts.content_type= joyent_file.joyent_file_type.mime_type
      # fts.file_name = joyent_file.filename
      # fts.attachment = attachment
      # fts.full_path = joyent_file.path_on_disk
      # # now set it in the mongrel_request
      # @response.instance_variable_get("@cgi").instance_variable_get("@response").file_to_send= fts
      # # XXX
      # fts
      send_file joyent_file.path_on_disk, :type => joyent_file.joyent_file_type.mime_type, :disposition => (attachment ? 'downloaded' : 'inline')
    end
end