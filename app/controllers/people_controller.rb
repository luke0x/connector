=begin #(fold)
Copyright 2004-2007 Joyent Inc.

Redistribution and/or modification of this code is governed
by either the GPLv2 or Joyent Commercial Software licenses.

Report issues and contribute at http://dev.joyent.com/

$Id$
=end #(end)

class PeopleController < AuthenticatedController
  before_filter :load_sort_order, :only => [:list]

  def current_group_id
    if    @smart_group  then @smart_group.url_id
    elsif @contact_list then @contact_list.id
    elsif @group_name   then @group_name
    else  nil
    end
  end

  def index
    redirect_to people_list_url(:group => current_user.contact_list.id)
  end

  def create
    @view_kind = 'create'
    @toolbar[:quota]  = true
    @toolbar[:new]    = false
    @toolbar[:import] = false
    @person = Person.new

    if request.post?
      @person.save_from_params(params[:person])

      params[:new_item_tags].split(',,').each do |tag_name|
        current_user.tag_item(@person, tag_name)
      end unless params[:new_item_tags].blank?
      params[:new_item_permissions].split(',').each do |user_dom_id|
        next unless user = find_by_dom_id(user_dom_id)
        @person.add_permission(user)
      end unless params[:new_item_permissions].blank?
      params[:new_item_notifications].split(',').each do |user_dom_id|
        next unless user = find_by_dom_id(user_dom_id)
        user.notify_of(@person, current_user)
      end unless params[:new_item_notifications].blank?

      redirect_to person_show_url(:id => @person.id) and return
    end

    render :action => 'edit'
  end             
  
  def copy
    person_ids   = params[:id] ? Array(params[:id]) : params[:ids].split(',') 
    contact_list = current_user.contact_list
    new_person   = nil
            
    if person_ids && contact_list    
      person_ids.each do |person_id|
        if person = Person.find(person_id, :scope => :copy)
          new_person = person.copy_to(contact_list)
        end
      end
         
      if person_ids.size > 1
        redirect_to people_list_url(:group => current_user.contact_list.id)
      elsif new_person
        redirect_to person_show_url(:id => new_person.id)
      else
        redirect_to people_home_url        
      end
    else
      redirect_to people_home_url
    end
  rescue ActiveRecord::RecordNotFound
    redirect_to people_home_url
  end

  def delete
    if ! request.post? or params[:ids].blank?
      redirect_back_or_home and return
    end
    
    ids = params[:ids].split(',')
    deleted_items = []

    ids.each do |id|
      begin
        item = Person.find(id, :scope => :delete)
        item_person = item
        item = item.user if item.user
        if current_user.can_delete?(item)
          item.destroy
          deleted_items << item_person
        end
      rescue ActiveRecord::RecordNotFound
      end
    end

    respond_to do |wants|
      wants.html { redirect_back_or_home }
      wants.js   {
        render :update do |page|
          deleted_items.each do |item|
            page << "Item.removeFromList('#{item.dom_id}');"
          end
          page << 'JoyentPage.refresh()';
        end
      }
    end      
  end

  def list
    @view_kind = 'list'
    if params[:group] =~ /^\d+$/
      contacts_list
    elsif params[:group] == 'users'
      users_list
    elsif params[:group] =~ /s(\d+)/
      smart_list
    else
      redirect_to '/'
    end
  end

  def show
    @view_kind = 'show'
    @person = Person.find(params[:id], :scope => :read)
    @smart_group_id = $1 if request.env.has_key?('HTTP_REFERER') and request.env['HTTP_REFERER'] =~ /\/s(\d+)$/

    if @smart_group_id
      smart_show
    elsif @person.user # admin/user/guest
      users_show
    else
      contacts_show
    end
  rescue ActiveRecord::RecordNotFound
    redirect_to people_home_url
  end

  def edit
    @view_kind = 'edit'
    person = Person.find(params[:id], :scope => :edit)
    person.user ? users_edit : contacts_edit
  rescue ActiveRecord::RecordNotFound
    redirect_to people_home_url
  end

  def vcards
    if params[:group] =~ /^\d+$/
      contacts_vcards
    elsif params[:group] == 'users'
      users_vcards
    elsif params[:group] == 'notifications'
      notifications_vcards
    elsif params[:group] =~ /s(\d+)/
      smart_vcards
    else
      redirect_to people_home_url
    end
  end

  def delete_confirm
    raise unless current_user.admin?

    @people = Person.find(params[:ids].split(','), :scope => :delete)
    raise if @people.blank?

    render :action => 'confirm_user_delete', :layout => false
  rescue
    render :text => 'error'
  end

  def vcard
    @person = Person.find(params[:id], :scope => :read)
    send_data @person.to_vcard, :filename => "#{@person.full_name.gsub(/\s/, '_')}.vcf"
  rescue ActiveRecord::RecordNotFound
    redirect_to people_home_url
  end
  
  def import
    if uploaded_file = params[:vcard]
      begin
        people = Person.from_vcards(uploaded_file.read)
         
        Person.transaction do
          people.each do |person|             
            person.owner        = current_user
            person.organization = current_organization
            person.contact_list = current_user.contact_list
            person.save
          end
        end
      rescue
        flash['error'] = _("There was a problem importing %{i18n_vcard_file}. Please be sure it is a valid vCard file.")%{:i18n_vcard_file => "'#{uploaded_file.original_filename}'"}  
      end
    end
  ensure
    redirect_back_or_home
  end
  
  def icon        
    @person = Person.find(params[:id], :scope => :read)
    send_data @person.icon, :type => "image/#{@person.icon_type}", :disposition => 'inline'
  rescue ActiveRecord::RecordNotFound
    render :nothing => true
  end

  def remove_icon
    @person = Person.find(params[:id], :scope => :edit)
    @person.remove_icon

    respond_to do |wants|
      wants.js {
        render :update do |page|
          page['person_photo_area'].replace :partial => 'person_photo', :locals => { :person => @person }
        end
      }
    end
  rescue ActiveRecord::RecordNotFound
    render :nothing => true
  end

  # for the delete toolbar button
  def item_delete_url
    people_delete_url
  end
  helper_method :item_delete_url

  def item_class_name
    'Person'
  end

  def add_address
    render :update do |page|
      page.insert_html :bottom, 'person_addresses', :partial => 'person_address', :locals => {:address => Address.new}
    end
  end

  def add_email_address
    render :update do |page|
      page.insert_html :bottom, 'person_email_addresses', :partial => 'person_email_address', :locals => {:email_address => EmailAddress.new}
    end
  end

  def add_im_address
    render :update do |page|
      page.insert_html :bottom, 'person_im_addresses', :partial => 'person_im_address', :locals => {:im_address => ImAddress.new}
    end
  end

  def add_phone_number
    render :update do |page|
      page.insert_html :bottom, 'person_phone_numbers', :partial => 'person_phone_number', :locals => {:phone_number => PhoneNumber.new}
    end
  end

  def add_special_date
    render :update do |page|
      page.insert_html :bottom, 'person_special_dates', :partial => 'person_special_date', :locals => {:special_date => SpecialDate.new}
    end
  end

  def add_website
    render :update do |page|
      page.insert_html :bottom, 'person_websites', :partial => 'person_website', :locals => {:website => Website.new}
    end
  end

  def notifications
    @view_kind = 'notifications'
    @toolbar[:import] = false
    @toolbar[:call] = false
    notice_count = current_user.notifications_count('Person', params.has_key?(:all))
    @paginator   = Paginator.new(self, notice_count, JoyentConfig.page_limit, params[:page])

    if params.has_key?(:all)
      @group_name = _('All Notifications')
      @show_all = true
      @notifications = selected_user.notifications.find(:all, 
                                                        :conditions => ["notifications.item_type = 'Person' "],
                                                        :include    => {:notifier => [:person]},
                                                        :order      => "notifications.created_at DESC",
                                                        :limit      => @paginator.items_per_page, 
                                                        :offset     => @paginator.current.offset)
      @toolbar[:new_notifications] = true
    else                    
      @group_name = _('Notifications')
      @show_all = false
      @notifications = selected_user.current_notifications.find(:all, 
                                                                :conditions => ["notifications.item_type = 'Person' "], 
                                                                :include    => {:notifier => [:person]},
                                                                :order      => "notifications.created_at DESC",
                                                                :limit      => @paginator.items_per_page, 
                                                                :offset     => @paginator.current.offset)
      @toolbar[:all_notifications] = true
    end

    respond_to do |wants|
      wants.html { render :template => 'notifications/list'                        }
      wants.js   { render :partial  => 'reports/notifications', 
                          :locals   => {:show_all => @show_all} }
    end
  end 
    
  def current_time                                                     
    @view_kind    = 'report'
    @group_name   = "Current Time"
    timezones     = {} # So we can properly sort the users within a timezone and they will all have the same time
    @people       = current_organization.users(:include => :person).sort do |user_a, user_b|
      a_time = (timezones[user_a.tz.to_s] ||= user_a.now)
      b_time = (timezones[user_b.tz.to_s] ||= user_b.now)      
      
      (a_time <=> b_time) != 0 ? a_time <=> b_time : user_a.full_name <=> user_b.full_name
    end.collect(&:person)

    @paginator = Paginator.new self, @people.size, JoyentConfig.page_limit, params[:page]                                               

    respond_to do |wants|
      wants.html 
      wants.js   { render :partial => 'reports/timezones'}
    end
  end
  
  def call
    current_user.update_attributes({:jajah_username => params[:jajah_username],
                                    :jajah_password => params[:jajah_password]})
    phone_numbers  = PhoneNumber.find(params[:jajah_to_numbers])
    actual_numbers = phone_numbers.collect{|p| p.phone_number}

    begin
      status_code    = User.jajah_system.call(current_user, params[:jajah_from_number], actual_numbers)
      flash[:status] = "Dialing..."
    rescue JajahError => e
      status_code    = e.code
      flash[:status] = "Could not complete call (#{e.message})"
    end

    # create the log entry
    call = current_user.calls.create(:status_code => status_code)
    phone_numbers.each do |phone|
      call.callings.create(:callee_id => phone.person_id, :phone_number => phone.phone_number)
    end
    
    respond_to do |wants|
      wants.html {redirect_back_or_home}
      wants.js {
        render :update do |page|
        page['jajah_status'].replace_html flash[:status]
        end
      }
    end
  end
  
  verify :xhr  => true,
         :only => :call_list
  def call_list
    person_ids   = params[:id] ? Array(params[:id]) : params[:ids].split(',') 
    contact_list = current_user.contact_list
    people       = []
    
    if person_ids && contact_list    
      person_ids.each do |person_id|
        if person = Person.find(person_id, :scope => :read)
          people << person
        end
      end
    end
    
    render :partial => "callee", :collection => people
  rescue ActiveRecord::RecordNotFound
    render :nothing => true
  end
  
  verify :xhr  => true,
         :only => :get_jajah_info
  def get_jajah_info      
    begin
      if params[:jajah_username].blank? || params[:jajah_password].blank?
        numbers        = {}
        balance        = "??"
        flash[:status] = "Empty Jajah credentials."
      else
        numbers = User.jajah_system.get_numbers(params[:jajah_username], params[:jajah_password])
        balance = User.jajah_system.get_balance(params[:jajah_username], params[:jajah_password])      
        balance = "%.2f (#{balance[1]})" % balance[0]
      
        current_user.update_attributes({:jajah_username => params[:jajah_username],
                                        :jajah_password => params[:jajah_password]})
      
        flash[:status] = "Valid login."
      end
    rescue JajahError => e
      numbers = {}
      balance = "??"
      flash[:status] = "Could not authenticate (#{e.message})"
    end

    render :update do |page|
      page['jajah_from_number'].replace_html ''
      numbers.values.flatten.each do |number|
        page.insert_html :bottom, 'jajah_from_number', "<option>#{number}</option>"
      end
      page['jajah_balance'].replace_html balance
      page['jajah_status'].replace_html  flash[:status]
    end
  end
  
  protected

    # list

    def contacts_list
      @contact_list     = ContactList.find(params[:group], :scope => :read)
      selected_user     = @contact_list.owner
      @group_name       = _('Contacts')
    
      people_count      = Person.restricted_count(:conditions => ['contact_list_id = ?', @contact_list.id])
      @paginator        = Paginator.new self, people_count, JoyentConfig.page_limit, params[:page]
    
      @people           = @contact_list.people.find(:all,
                                                    :order  => "LOWER(people.#{@sort_field}) #{@sort_order}",
                                                    :limit  => @paginator.items_per_page,
                                                    :offset => @paginator.current.offset,
                                                    :include => [:user, :permissions, :notifications, :taggings],
                                                    :scope => :read)

      @toolbar[:copy]   = current_user.can_copy_from?(@contact_list)
      @toolbar[:call]   = current_user.can_copy_from?(@contact_list)
      @toolbar[:delete] = current_user.can_delete_from?(@contact_list)
    
      respond_to do |wants|
        wants.html { render :action  => 'list'   }
        wants.js   { render :partial => 'reports/people' }
      end    
    rescue ActiveRecord::RecordNotFound
      redirect_to people_home_url
    end

    def users_list
      @group_name  = _('Users')
      people_count = current_organization.people.restricted_count(:conditions => [ "person_type IN (?)", ['0_Admin', '1_User', '1_User_Guest'] ])
      @paginator   = Paginator.new(self, people_count, JoyentConfig.page_limit, params[:page])
      @people      = current_organization.people.find(:all,
                                                      :conditions => [ "person_type IN (?)", ['0_Admin', '1_User', '1_User_Guest'] ],
                                                      :order      => "LOWER(#{@sort_field}) #{@sort_order}",
                                                      :include    => [:user, :permissions, :notifications, :taggings],
                                                      :limit      => @paginator.items_per_page,
                                                      :offset     => @paginator.current.offset,
                                                      :scope      => :read)

      @toolbar[:quota]  = true
      @toolbar[:copy]   = true
      @toolbar[:call]   = true
      @toolbar[:delete] = current_user.admin?

      respond_to do |wants|
        wants.html { render :action  => 'list'   }
        wants.js   { render :partial => 'reports/people' }
      end
    end

    def smart_list
      @smart_group  = SmartGroup.find(SmartGroup.param_to_id(params[:group]), :scope => :read)
      selected_user = @smart_group.owner
      @group_name   = @smart_group.name
    
      @paginator = Paginator.new self, @smart_group.items_count, JoyentConfig.page_limit, params[:page]
      @people    = @smart_group.items("people.#{@sort_field} #{@sort_order}", @paginator.items_per_page, @paginator.current.offset)

      # It appears that the pagination doesn't do much, so lets page now
      @people      = @people[@paginator.current.offset, @paginator.items_per_page]

      @toolbar[:copy]   = current_user.can_copy_from?(@smart_group) 
      @toolbar[:call]   = current_user.can_copy_from?(@smart_group)       
      @toolbar[:delete] = current_user.can_delete_from?(@smart_group) 

      respond_to do |wants|
        wants.html { render :action  => 'list'   }
        wants.js   { render :partial => 'reports/people' }  
      end    
    rescue ActiveRecord::RecordNotFound
      redirect_to people_home_url
    end

    # show
  
    def contacts_show
      selected_user     = @person.owner
      @contact_list     = selected_user.contact_list
      @group_name       = _('Contacts')

      @toolbar[:edit]   = current_user.can_edit?(@person)           
      @toolbar[:copy]   = current_user.can_copy?(@person)
      @toolbar[:call]   = current_user.can_copy?(@person)      
      @toolbar[:delete] = current_user.can_delete?(@person)

      respond_to do |wants|
        wants.html { render :action => 'show' }
        wants.js   { render :update do |page|
          page[params[:update_id]].replace_html :partial => 'peek'
        end }
      end
    rescue ActiveRecord::RecordNotFound
      redirect_to people_home_url
    end  

    def users_show           
      @group_name       = _('Users')

      @toolbar[:quota]  = true
      @toolbar[:edit]   = current_user.can_edit?(@person)
      @toolbar[:copy]   = current_user.can_copy?(@person) 
      @toolbar[:call]   = current_user.can_copy?(@person)       
      @toolbar[:delete] = current_user.can_delete?(@person)
                                               
      respond_to do |wants|
        wants.html { render :action => 'show' }
        wants.js   { render :update do |page|
          page[params[:update_id]].replace_html :partial => 'peek'
        end }
      end
    rescue ActiveRecord::RecordNotFound
      redirect_to people_home_url
    end

    def smart_show
      @smart_group  = SmartGroup.find(SmartGroup.param_to_id(@smart_group_id), :scope => :read)
      selected_user = @smart_group.owner
      @group_name   = @smart_group.name

      @toolbar[:edit]   = current_user.can_edit?(@person)
      @toolbar[:copy]   = current_user.can_copy?(@person)
      @toolbar[:call]   = current_user.can_copy?(@person)      
      @toolbar[:delete] = current_user.can_delete?(@person)

      respond_to do |wants|
        wants.html { render :action => 'show' }
        wants.js   { render :update do |page|
          page[params[:update_id]].replace_html :partial => 'peek'
        end }
      end
    rescue ActiveRecord::RecordNotFound
      redirect_to people_home_url
    end

    # edit

    def contacts_edit
      @contact_list = current_user.contact_list
      selected_user = @contact_list.owner
      @group_name   = _('Contacts')
      @person       = Person.find(params[:id], :scope => :read)

      @toolbar[:quota]  = true
      @toolbar[:copy]   = current_user.can_copy?(@person) 
      @toolbar[:call]   = current_user.can_copy?(@person)       
      @toolbar[:delete] = current_user.can_delete?(@person)
                      
      if request.post?
        @failed = @person.save_from_params(params[:person])
        redirect_to person_show_url(:id => @person.id)
        return true
      end
      render :action => 'edit'
    rescue ActiveRecord::RecordNotFound
      redirect_to people_home_url
    end

    def users_edit
      @person           = Person.find(params[:id], :scope => :edit)
      @group_name       = _('Users')
      @toolbar[:quota]  = true
      @toolbar[:copy]   = current_user.can_copy?(@person) 
      @toolbar[:call]   = current_user.can_copy?(@person)       
      @toolbar[:delete] = current_user.can_delete?(@person)
    
      if ! current_user.can_edit?(@person)
        redirect_to people_list_url(:group => 'users')
        return true
      end                                               
                 
      if request.post?
        @failed = @person.save_from_params(params[:person])
        redirect_to person_show_url(:id => @person)
        return true
      end
      render :action => 'edit'
    rescue ActiveRecord::RecordNotFound
      redirect_to people_home_url
    end

    # vcards
  
    def contacts_vcards
      @contact_list = current_user.contact_list
      selected_user = @contact_list.owner
      @people       = @contact_list.people.find(:all, :scope => :read)
      vcards        = VcardConverter.create_vcards_from_people(@people)
      send_data vcards, :filename => "Contacts.vcf"
    rescue
      render :nothing => true
    end

    def users_vcards
      @group_name = _('Users')
      @users      = User.find(:all, :scope => :read)
      @people     = @users.map(&:person)
      vcards      = VcardConverter.create_vcards_from_people(@people)
      send_data vcards, :filename => "Users.vcf"
    rescue
      render :nothing => true
    end

    def notifications_vcards
      @people     = current_organization.notifications.find(:all, :conditions => ["item_type = 'Person' and notifiee_id = ?", current_user.id]).collect(&:item)
      vcards      = VcardConverter.create_vcards_from_people(@people)
      send_data vcards, :filename => "Notifications.vcf"
    rescue 
      render :nothing => true
    end

    def smart_vcards
      @smart_group  = SmartGroup.find(SmartGroup.param_to_id(params[:group]), :scope => :read)
      selected_user = @smart_group.owner
      @group_name   = @smart_group.name
      @people       = @smart_group.items
      vcards        = VcardConverter.create_vcards_from_people(@people)
      send_data vcards, :filename => "#{@smart_group.name.gsub(/\s/, '_')}.vcf"
    rescue
      render :nothing => true
    end

  private

    def setup_toolbar
      super
      @toolbar[:quota]  = false
      @toolbar[:new]    = true
      @toolbar[:edit]   = false    
      @toolbar[:copy]   = false
      @toolbar[:delete] = false
      @toolbar[:import] = true     
      @toolbar[:call]   = true
      true
    end            

    def valid_sort_fields
      ['person_type', 'first_name', 'last_name', 'company_name', 'primary_email_cache', 'primary_phone_cache']
    end

    def default_sort_field
      'last_name'
    end

    def default_sort_order
      'ASC'
    end
end