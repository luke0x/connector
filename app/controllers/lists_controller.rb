=begin #(fold)
Copyright 2004-2007 Joyent Inc.

Redistribution and/or modification of this code is governed
by either the GPLv2 or Joyent Commercial Software licenses.

Report issues and contribute at http://dev.joyent.com/

$Id$
=end #(end)

class ListsController < AuthenticatedController
  before_filter :load_sort_order, :only => [:index]

  # REST
  
  # GET /lists
  # GET /lists.xml
  def index
    @view_kind = 'list'

    @toolbar[:new] = true
    @toolbar[:copy] = true
    @toolbar[:move] = true
    @toolbar[:delete] = true
    @toolbar[:import] = true

    if params[:group] =~ /^\d+$/
      index_list_folder
    elsif params[:group] =~ /^s(\d+)$/
      index_smart_group
    else
      redirect_to lists_home_url and return
    end
    
    respond_to do |format|
      format.html # index.rhtml
      format.xml { render :xml => @lists.to_xml }
      format.js { render :partial => 'reports/lists' }
    end
  rescue ActiveRecord::RecordNotFound
    redirect_to lists_home_url
  end

  # GET /lists/1
  # GET /lists/1.xml
  def show
    @list = List.find(params[:id], :include => [:list_columns, {:list_rows => [:list_cells]}], :scope => :read)
    List.current = @list

    User.selected = @list.owner
    @list_folder = @list.list_folder
    @group_name = @list_folder.name

    @toolbar[:new] = true
    @toolbar[:tools] = true

    respond_to do |format|
      format.html do
        if User.current.can_edit?(@list)
          redirect_to edit_list_url(@list)
        else
          render :action => 'show'
        end
      end
      format.js do
        render :update do |page|
          page[params[:update_id]].replace_html :partial => 'peek'
          # page.replace_html 'listContainer', :partial => 'list' # not sure if this is used
        end
      end
      format.xml  { render :xml => @list.to_xml }
      format.opml { send_data @list.to_opml, :type => Mime::OPML.to_s, :filename => "#{@list.name}.opml" }
    end
  rescue ActiveRecord::RecordNotFound
    redirect_to lists_home_url
  end

  # GET /lists/new
  def new
    @list = List.new
    @list_folder = User.current.lists_list_folder
    
    @toolbar[:new] = true
    @toolbar[:import] = true
  end

  # GET /lists/1;edit
  def edit
    @list = List.find(params[:id], :include => [:list_columns, {:list_rows => [:list_cells]}], :scope => :edit)
    List.current = @list

    User.selected = @list.owner
    @list_folder = @list.list_folder
    @group_name = @list_folder.name

    @toolbar[:new_row] = true
    @toolbar[:move_row] = true
    @toolbar[:delete_row] = true
    @toolbar[:edit] = User.current.can_edit?(@list)
    @toolbar[:new] = true
    @toolbar[:tools] = true
    
    respond_to do |format|
      format.html { render :action => 'show' }
    end
  rescue ActiveRecord::RecordNotFound
    redirect_to list_url(params[:id])
  end

  # POST /lists
  # POST /lists.xml
  def create
    list_params = params[:list].merge(:organization_id => User.current.organization.id, :user_id => User.current.id)
    @list = List.new(list_params)

    respond_to do |format|
      if @list.save
        flash[:message] = 'List was successfully created.'
        format.html { redirect_to list_url(@list) }
        format.xml  { head :created, :location => list_url(@list) }
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => @list.errors.to_xml }
      end
    end
  end

  # PUT /lists/1
  # PUT /lists/1.xml
  def update
    @list = List.find(params[:id], :include => [:list_columns, {:list_rows => [:list_cells]}], :scope => :edit)

    respond_to do |format|
      if @list.update_attributes(params[:list])
        format.js  { render :update do |page|
          page.replace_html 'listNameShowView', @list.name
          page.replace_html 'drawerEdit', :partial => 'edit'
        end }
        format.xml { head :ok }
      else
        format.js  { render :nothing => true }
        format.xml { render :xml => @list.errors.to_xml }
      end
    end
  end

  # DELETE /lists/1
  # DELETE /lists/1.xml
  def destroy
    @list = List.find(params[:id], :include => [:list_columns, {:list_rows => [:list_cells]}], :scope => :delete)
    @list.destroy

    respond_to do |format|
      format.html { redirect_to lists_url }
      format.xml  { head :ok }
    end
  end
  
  # NON-REST

  def current_group_id
    if    @smart_group  then @smart_group.url_id
    elsif @list_folder  then @list_folder.id
    elsif @group_name   then @group_name
    else  nil
    end
  end

  def self.group_name
    'ListFolder'
  end

  def item_class_name
    'List'
  end

  def delete
    if ! request.post? or params[:ids].blank?
      redirect_back_or_home and return
    end

    ids = params[:ids].split(',')
    deleted = []
    
    ids.each do |id|
      begin
        list = List.find(id, :include => [:list_columns, {:list_rows => [:list_cells]}], :scope => :delete)
        list.destroy
        deleted << list
      rescue ActiveRecord::RecordNotFound
      end
    end

    respond_to do |wants|
      wants.html { redirect_back_or_home }
      wants.js   {
        render :update do |page|
          deleted.each do |list|
            page << "Item.removeFromList('#{list.dom_id}');"
          end
          page << 'JoyentPage.refresh()';
        end
      }
    end      
  end
  
  def notifications
    @view_kind = 'notifications'
    notice_count = User.current.notifications_count('List', params.has_key?(:all))
    @paginator = Paginator.new self, notice_count, JoyentConfig.page_limit, params[:page]

    @toolbar[:new] = true

    if params.has_key?(:all)
      @group_name = _('All Notifications')
      @show_all = true
      @notifications = User.current.notifications.find(:all, :conditions => ["notifications.item_type = 'List' "], :limit => @paginator.items_per_page, :offset => @paginator.current.offset)
      @toolbar[:new_notifications] = true
    else
      @group_name = _('Notifications')
      @show_all = false
      @notifications = User.current.current_notifications.find(:all, :conditions => ["notifications.item_type = 'List' "], :limit => @paginator.items_per_page, :offset => @paginator.current.offset)
      @toolbar[:all_notifications] = true
    end
    
    respond_to do |wants|
      wants.html { render :template => 'notifications/list' }
      wants.js   { render :partial  => 'reports/notifications', :locals   => {:show_all => @show_all} }
    end    
  end

  def expand_all
    @list = List.find(params[:id], :include => [:list_columns, {:list_rows => [:list_cells]}], :scope => :edit)
    @list.expand!

    respond_to do |format|
      format.js  { render :nothing => true }
      format.xml { head :ok }
    end
  end
  
  def collapse_all
    @list = List.find(params[:id], :include => [:list_columns, {:list_rows => [:list_cells]}], :scope => :edit)
    @list.collapse!

    respond_to do |format|
      format.js  { render :nothing => true }
      format.xml { head :ok }
    end
  end

  def item_delete_url
    url_for(:controller => 'lists', :action => 'delete')
  end
  helper_method :item_delete_url 

  def move
    ids = params[:ids].split(',')
    list_folder = ListFolder.find(params[:new_group_id], :scope => :create_on)
    return unless ids
    return unless list_folder

    ids.each do |id|
      if list = List.find(id, :scope => :move)
        list.move_to!(list_folder)
      end
    end
  ensure
    redirect_back_or_home
  end

  def copy
    ids = params[:ids].split(',')
    list_folder = ListFolder.find(params[:new_group_id], :scope => :create_on)
    return unless ids
    return unless list_folder

    ids.each do |id|
      if list = List.find(id, :include => [:list_columns, {:list_rows => [:list_cells]}], :scope => :copy)
        list.copy_to!(list_folder)
      end
    end
  ensure
    redirect_back_or_home
  end

  def item_move_url
    move_list_url
  end
  helper_method :item_move_url

  def item_copy_url
    copy_list_url
  end
  helper_method :item_copy_url
  
  def import
    #take in consideration group
    if uploaded_file = params[:opml_file]
      List.new_from_opml(uploaded_file.read, params[:group])
    end
  rescue => e
    logger.error "Exception occurred importing file #{e}"
    flash[:error] = _("There was a problem importing the OPML file '%{i18n_opml_file}'. Please be sure that it is a valid file.")%{:i18n_opml_file => "#{uploaded_file.original_filename}"}
  ensure
    redirect_back_or_home
  end

  # TODO: non-crud non-list actions, should go to list_folder_controller eventually
  
  def create_list_folder
    @list_folder = User.current.list_folders.build(:name => params[:group_name], :parent_id => params[:parent_id], :organization_id => User.current.organization_id)

    if @list_folder.save
      flash[:message] = _('List folder successfully created.')
    else
      flash[:error] = _("An error occurred creating the list folder.")
    end
  ensure
    redirect_back_or_home
  end

  def rename_group
    @list_folder = User.current.list_folders.find(params[:id])

    if @list_folder.rename! params[:name]
      flash[:message] = _('List folder successfully renamed.')
    else
      flash[:error] = _("An error occurred renaming the list folder.")
    end
  ensure
    redirect_back_or_home
  end

  def delete_group
    @list_folder = User.current.list_folders.find(params[:id])
    @list_folder.destroy

    respond_to do |format|
      format.html { redirect_to lists_home_url }
      format.xml  { head :ok }
    end
  end

  def reparent_group
    return unless params[:group_id]
    return unless params[:new_parent_id]

    group = User.current.list_folders.find_by_id(params[:group_id])
    return unless group

    new_parent = User.current.list_folders.find(params[:new_parent_id]) rescue nil

    group.reparent!(new_parent)
  ensure
    redirect_back_or_home
  end
  
  protected
  
    def index_list_folder
      @list_folder   = ListFolder.find(params[:group], :scope => :read)
      User.selected = @list_folder.owner
      @group_name   = @list_folder.name
      @paginator    = Paginator.new self, @list_folder.lists.count, JoyentConfig.page_limit, params[:page]
      @lists  = List.find(:all,
                          :conditions => ["list_folder_id = ?", @list_folder.id],
                          :order      => "lists.#{@sort_field} #{@sort_order}",
                          :limit      => @paginator.items_per_page,
                          :offset     => @paginator.current.offset,
                          :scope      => :read)
    end

    def index_smart_group
      @smart_group = SmartGroup.find(SmartGroup.param_to_id(params[:group]), :scope => :read)
      User.selected = @smart_group.owner
      @group_name = @smart_group.name

      @paginator        = Paginator.new self, @smart_group.items.size, JoyentConfig.page_limit, params[:page]
      @lists            = @smart_group.items(nil, @paginator.items_per_page, @paginator.current.offset).sort_by(&@sort_field.to_sym)
      @lists.reverse!     if @sort_order == 'DESC'
    end

  private

    def valid_sort_fields
      ['name', 'updated_at']
    end

    def default_sort_field
      'name'
    end

    def default_sort_order
      'ASC'
    end

end