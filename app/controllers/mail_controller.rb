=begin #(fold)
++
Copyright 2004-2007 Joyent Inc.

Redistribution and/or modification of this code is 
governed by the GPLv2.

Report issues and contribute at http://dev.joyent.com/

$Id$
--
=end #(end)

class MailController < AuthenticatedController
  before_filter :sync_mailboxes, :except => [:index, :show_body, :external_show,
                                             :delete, :move, :copy, :unavailable,
                                             :mark_spam, :mark_not_spam,
                                             :create_mailbox, :rename_group,
                                             :delete_group, :send_draft, :send_compose,
                                             :send_reply_to, :send_forward, :attachment,
                                             :empty_spam, :empty_trash, :groups_ids,
                                             :others_groups, :flag, :unflag, :inbox_unread_count, 
                                             :away_message_edit, :away_message_update, :add_group_emails_ajax, :groups_addresses_for_lookup]
  before_filter :load_sort_order, :only => [:special_list, :list, :smart_list, :special_show, :show, :smart_show]
  before_filter :load_mail_aliases, :only => [:special_list, :list, :smart_list, :special_show, :show, :smart_show, :compose, :reply_to, :forward, :edit_draft, :notifications, :unread_messages]
#  after_filter(:only => [:create_mailbox, :rename_group, :delete_group, :reparent_group]){ |c| c.expire_fragment %r{mail/sidebar} }

  def index
    redirect_to mail_special_list_url(:id => 'inbox')
  end

  def special_list
    @view_kind = 'list'

    params[:id] ||= ''
    mailbox       = params[:id] == 'inbox' ? 'INBOX' : "INBOX.#{params[:id].capitalize}"
    @mailbox      = current_user.mailboxes.find(:first, :conditions => ['mailboxes.full_name = ?', mailbox], :include => [:owner], :scope => :read)
    raise ActiveRecord::RecordNotFound if @mailbox.blank? # do this manually since we're not using id

    @group_name   = params[:id].capitalize 
    @mailbox_name = params[:id]

    @mailbox.sync
    
    self.selected_user = @mailbox.owner
    message_count = Message.restricted_count(:conditions => ['mailbox_id = ? AND messages.active = ?', @mailbox.id, true])
    @paginator    = Paginator.new self, message_count, JoyentConfig.page_limit, params[:page]
    @messages     = @mailbox.messages.find(:all, 
                                            :conditions => ['messages.active = ?', true],
                                            :order      => "messages.#{@sort_field} #{@sort_order}",
                                            :limit      => @paginator.items_per_page,
                                            :offset     => @paginator.current.offset,
                                            :include    => [:owner, :permissions, :notifications, :taggings],
                                            :scope      => :read)

    @toolbar[:compose] = true
    @toolbar[:copy]    = true
    @toolbar[:move]    = true
    @toolbar[:delete]  = true
    @toolbar[:spam]        = ! (@mailbox && @mailbox.full_name == 'INBOX.Spam')
    @toolbar[:not_spam]    = @mailbox && @mailbox.full_name == 'INBOX.Spam'
    @toolbar[:empty_spam]  = @mailbox && @mailbox.full_name == 'INBOX.Spam' && current_user.owns?(@mailbox)
    @toolbar[:empty_trash] = @mailbox && @mailbox.full_name == 'INBOX.Trash' && current_user.owns?(@mailbox)
    @toolbar[:tools]       = true
    @toolbar[:away]  = @mailbox && @mailbox.full_name == 'INBOX' && current_user.owns?(@mailbox)

    respond_to do |wants|
      wants.html { render :action => 'list' }
      wants.js   { render :partial => 'reports/messages', :locals => {:mailbox      => @mailbox, 
                                                               :mailbox_name => @mailbox_name} }  
    end
  rescue ActiveRecord::RecordNotFound
    redirect_to mail_home_url
  end

  def list
    @view_kind     = 'list'
    @mailbox       = Mailbox.find(params[:id], :include => [:owner], :scope => :read)
    @mailbox.sync
    
    self.selected_user  = @mailbox.owner
    @mailbox_name  = @mailbox.id
    @group_name    = (@mailbox.name == 'INBOX') ? 'Inbox' : @mailbox.name
    @paginator     = Paginator.new self, @mailbox.messages.count(:conditions => ["messages.active = ?", true]), JoyentConfig.page_limit, params[:page]
    @messages      = @mailbox.messages.find(:all,
                                            :conditions => ["messages.active = ?", true],
                                            :order      => "messages.#{@sort_field} #{@sort_order}",
                                            :limit      => @paginator.items_per_page,
                                            :offset     => @paginator.current.offset,
                                            :include    => [:owner, :permissions, :notifications, :taggings],
                                            :scope      => :read)

    @toolbar[:compose]     = true
    @toolbar[:copy]        = true
    @toolbar[:move]        = true
    @toolbar[:delete]      = true
    @toolbar[:spam]        = ! (@mailbox && @mailbox.full_name == 'INBOX.Spam')
    @toolbar[:not_spam]    = @mailbox && @mailbox.full_name == 'INBOX.Spam'
    @toolbar[:empty_spam]  = @mailbox && @mailbox.full_name == 'INBOX.Spam' && current_user.owns?(@mailbox)
    @toolbar[:empty_trash] = @mailbox && @mailbox.full_name == 'INBOX.Trash' && current_user.owns?(@mailbox)
    @toolbar[:tools]       = true
    
    respond_to do |wants|
      wants.html { render :action => 'list' }
      wants.js   { render :partial => 'reports/messages', :locals => {:mailbox      => @mailbox, 
                                                               :mailbox_name => @mailbox_name} }  
    end
  rescue ActiveRecord::RecordNotFound
    redirect_to mail_home_url
  end

  def smart_list
    @view_kind    = 'list'
    @smart_group  = SmartGroup.find(SmartGroup.param_to_id(params[:smart_group_id]), :scope => :read)
    self.selected_user = @smart_group.owner
    @group_name   = @smart_group.name

    @messages  = @smart_group.items("messages.#{@sort_field} #{@sort_order}", nil, nil)
    @messages  = @messages.select{|m| m.exist?}
    @paginator = Paginator.new self, @messages.length, JoyentConfig.page_limit, params[:page]
    @messages  = @messages[@paginator.current.offset, @paginator.items_per_page]

    @toolbar[:compose] = true
    @toolbar[:copy]    = true
    @toolbar[:move]    = true
    @toolbar[:delete]  = true

    respond_to do |wants|
      wants.html { render :action  => 'list' }
      wants.js   { render :partial => 'reports/messages', :locals => {:mailbox      => nil, 
                                                                      :mailbox_name => nil} }
    end
  rescue ActiveRecord::RecordNotFound
    redirect_to mail_home_url
  end   
  
  def unread_messages
    @mailbox       = selected_user.inbox
    @mailbox.sync
    @group_name    = "Unread Messages"
    @mailbox_name  = @mailbox.id
    message_count  = Message.restricted_count(:conditions => ["(seen = ? OR seen IS NULL) AND messages.active = ? AND mailbox_id = ?", false, true, @mailbox.id])
    @paginator     = Paginator.new self, message_count, JoyentConfig.page_limit, params[:page]
    @messages      = @mailbox.messages.find(:all, 
                                            :conditions => ["(seen = ? OR seen IS NULL) AND messages.active = ?", false, true],
                                            :order      => "date DESC",
                                            :limit      => @paginator.items_per_page,
                                            :offset     => @paginator.current.offset,
                                            :include    => [:owner, :permissions, :notifications, :taggings],
                                            :scope      => :read)

    @toolbar[:compose] = true
    @toolbar[:copy]    = true
    @toolbar[:move]    = true
    @toolbar[:delete]  = true

    respond_to do |wants|
      wants.html { @view_kind = 'list'; render :action => 'list' }
      wants.js   { render :partial  => 'reports/messages', :locals => {:messages     => @messages, 
                                                                       :mailbox      => @mailbox, 
                                                                       :mailbox_name => @mailbox_name} }
    end
  end

  def special_show
    @view_kind = 'show'
    @group_name   = params[:mailbox].capitalize
    @mailbox_name = params[:mailbox]
    mailbox       = params[:mailbox] == 'inbox' ? 'INBOX' : "INBOX.#{params[:mailbox].capitalize}"
    @mailbox      = current_user.mailboxes.find(:first, :conditions => ['mailboxes.full_name = ?', mailbox], :include => [:owner], :scope => :read)
    @mailbox.sync
    self.selected_user = @mailbox.owner
    @message      = @mailbox.messages.find(params[:id], :conditions => ["messages.active = ?", true], :scope => :read)
    
    @message.seen!

    @messages = @mailbox.messages.find(:all, :conditions => ["messages.active = ?", true], :order => "messages.#{@sort_field} #{@sort_order}", :scope => :read)
    message_index = 0
    @messages.each{|message| message_index += 1; break if message == @message; }
    @paginator = Paginator.new self, @mailbox.messages.count(:conditions => ["messages.active = ?", true]), 1, message_index

    @toolbar[:compose]   = true
    @toolbar[:reply]     = true
    @toolbar[:reply_all] = true
    @toolbar[:forward]   = true
    @toolbar[:move]      = current_user.can_move?(@message)
    @toolbar[:copy]      = current_user.can_copy?(@message)
    @toolbar[:delete]    = current_user.can_delete?(@message)
    @toolbar[:spam]      = @message.mailbox.full_name != 'INBOX.Spam' and current_user.can_move?(@message)
    @toolbar[:not_spam]  = @message.mailbox.full_name == 'INBOX.Spam' and current_user.can_move?(@message)
    @toolbar[:tools]     = true

    respond_to do |wants|
      wants.html { render :action => 'show' }
    end
  rescue ActiveRecord::RecordNotFound, JoyentMaildir::MaildirFileNotFound
    if @mailbox
      redirect_to mail_special_list_url(:id => @mailbox_name)
    else
      redirect_to mail_home_url
    end
  end

  def show
    @view_kind = 'show'
    @mailbox      = Mailbox.find(params[:mailbox], :include => [:owner], :scope => :read)

    self.selected_user = @mailbox.owner
    @mailbox_name = @mailbox.id
    @group_name   = (@mailbox.name == 'INBOX') ? 'Inbox' : @mailbox.name
    @message      = @mailbox.messages.find(params[:id], :conditions => ["messages.active = ?", true], :scope => :read)
    @message.seen!

    @messages = @mailbox.messages.find(:all, :conditions => ['messages.active=?', true], :order => "messages.#{@sort_field} #{@sort_order}", :scope => :read)
    message_index = 0
    @messages.each{|message| message_index += 1; break if message == @message; }
    @paginator = Paginator.new self, @mailbox.messages.count(:conditions => ['messages.active=?', true]), 1, message_index

    @toolbar[:compose]   = true
    @toolbar[:reply]     = true
    @toolbar[:reply_all] = true
    @toolbar[:forward]   = true
    @toolbar[:move]      = current_user.can_move?(@message)
    @toolbar[:copy]      = current_user.can_copy?(@message)
    @toolbar[:delete]    = current_user.can_delete?(@message)
    @toolbar[:spam]      = @message.mailbox.full_name != 'INBOX.Spam' and current_user.can_move?(@message)
    @toolbar[:not_spam]  = @message.mailbox.full_name == 'INBOX.Spam' and current_user.can_move?(@message)
    @toolbar[:tools]     = true

    respond_to do |wants|
      wants.html { render :action => 'show' }
      # peek view from all show views
      wants.js   { render :update do |page|
        page[params[:update_id]].replace_html :partial => 'peek'
        page["status_icon_#{@message.dom_id}"].replace_html status_icon(@message)
        page << 'Mail.updateInboxUnreadCount();'
      end }
    end
  rescue JoyentMaildir::MaildirFileNotFound
    render :template => 'mail/deleted_mail'
  end
  
  def show_body
    @message = Message.find(params[:id], :conditions => ["messages.active = ?", true], :scope => :read)
    render :partial => 'show_body'
  rescue ActiveRecord::RecordNotFound
    redirect_to mail_home_url
  end
  
  def external_show
    @message = Message.find(params[:id], :conditions => ["messages.active = ?", true], :scope => :read)
    @mailbox = @message.mailbox
    redirect_to mail_message_show_url(:mailbox => @mailbox, :id => @message) 
  rescue ActiveRecord::RecordNotFound
    redirect_to mail_home_url
  end
  
  def smart_show
    @view_kind    = 'show'
    @smart_group  = SmartGroup.find(SmartGroup.param_to_id(params[:smart_group_id]), :scope => :read)
    self.selected_user = @smart_group.owner
    @group_name   = @smart_group.name
    @message      = Message.find(params[:id], :conditions => ["messages.active = ?", true], :scope => :read)
    @message.seen!

    @messages  = @smart_group.items("messages.#{@sort_field} #{@sort_order}", nil, nil)
    @messages  = @messages.select{|m| m.exist?}
    page = (@messages.index(@message) + 1) rescue 1
    @paginator = Paginator.new self, @messages.length, 1, page

    @toolbar[:compose]   = true
    @toolbar[:reply]     = true
    @toolbar[:reply_all] = true
    @toolbar[:forward]   = true
    @toolbar[:move]      = current_user.can_move?(@message)
    @toolbar[:copy]      = current_user.can_copy?(@message)
    @toolbar[:delete]    = current_user.can_delete?(@message)

    respond_to do |wants|
      wants.html { render :action => 'show' }
    end
  rescue ActiveRecord::RecordNotFound, JoyentMaildir::MaildirFileNotFound
    if @smart_group
      redirect_to mail_smart_list_url(:smart_group_id => @smart_group.id)
    else
      redirect_to mail_home_url
    end
  end
  
  def delete
    if ! request.post? or params[:ids].blank?
      redirect_back_or_home and return
    end

    ids = params[:ids].split(',')
    items = Message.find(ids, :conditions => ["messages.active = ?", true], :scope => :delete)

    items.each do |item|
      if item.exist?
        item.move_to(item.owner.trash)
      end
    end
    
    respond_to do |wants|
      wants.html { redirect_to mail_mailbox_url(:id => items.first.mailbox_id) }
      wants.js   {
        render :update do |page|
          items.each do |item|
            page << "Item.removeFromList('#{item.dom_id}');"
          end
          page << 'JoyentPage.refresh();'
          page << 'Mail.updateInboxUnreadCount();'
        end
      }
    end      
  end

  def move
    # Somehow, every now and then, from certain users, no params are sent along.
    if params[:id].blank? && params[:ids].blank?
      redirect_back_or_home
      return
    end
    
    message_ids = params[:id] ? Array(params[:id]) : params[:ids].split(',')
    mailbox     = current_user.mailboxes.find(params[:new_group_id])
    Message.find(message_ids, :conditions => ["messages.active = ?", true], :scope => :move).each do |msg|
      msg.move_to mailbox
    end
    if request.env.has_key?("HTTP_REFERER") && request.env['HTTP_REFERER'] =~ /(inbox|sent|drafts|trash|\d+)\/\d+$/
      redirect_to mail_mailbox_url(:id => mailbox.id)
    else
      redirect_back_or_home
    end
  end

  def copy
    message_ids = params[:id] ? Array(params[:id]) : params[:ids].split(',')
    mailbox     = current_user.mailboxes.find(params[:new_group_id])
    Message.find(message_ids, :conditions => ["messages.active = ?", true], :scope => :copy).each do |msg|
      msg.copy_to mailbox
    end
  rescue ActiveRecord::RecordNotFound
  ensure
    redirect_back_or_home
  end
  
  def mark_spam
    ids = params[:id] ? Array(params[:id]) : params[:ids].split(',')
    items = current_user.messages.find_all_by_id(ids)
    items.each do |item|
      next if item.mailbox.full_name == 'INBOX.Spam'
      item.seen!
      item.move_to item.owner.spam
      # TODO: maybe something more
    end
    
    respond_to do |wants|
      wants.html { redirect_back_or_home }
      wants.js   {
        render :update do |page|
          items.each do |item|
            page << "Item.removeFromList('#{item.dom_id}');"
          end
          page << 'JoyentPage.refresh();'
          page << 'Mail.updateInboxUnreadCount();'
        end
      }
    end
  end
  
  def mark_not_spam
    ids = params[:id] ? Array(params[:id]) : params[:ids].split(',')
    items = current_user.messages.find_all_by_id(ids)
    items.each do |item|
      next unless item.mailbox.full_name == 'INBOX.Spam'
      item.move_to item.owner.inbox
      # TODO: maybe something more
    end
    
    respond_to do |wants|
      wants.html { redirect_back_or_home }
      wants.js   {
        render :update do |page|
          items.each do |item|
            page << "Item.removeFromList('#{item.dom_id}');"
          end
          page << 'JoyentPage.refresh();'
          page << 'Mail.updateInboxUnreadCount();'
        end
      }
    end
  end
  
  def compose
    @view_kind = 'create'
    
    # Attach files from the files app
    if params[:ids]
      ids = params[:ids].split(',').collect{|id| id.strip}
      
      if params[:service]
        # From services
        service               = Service.find(params[:service], current_user)
        @files                = ids.collect{|id| service.find_file(id)}.compact if service
        @file_attachment_type = 'service_files'
      elsif ids.first.to_i == 0
        # From strongspace
        @files                = ids.collect{|id| StrongspaceFile.find(current_user, id, current_user) rescue nil}.compact
        @file_attachment_type = 'strongspace_files'
      else
        # From regular files
        @files                = JoyentFile.find(ids, :scope => :read)       
        @file_attachment_type = 'joyent_files'
      end
    end    
  end

  def quick_contact
    name       = params[:name]
    first_name = 'New'
    last_name  = 'Contact'    
    email      = params[:email]
    email_type = 'home'
    
    if name
      if name =~ /"(.*)"/
        name = $1
      end
    
      if name.index(',')
        last_name, first_name = name.split(',')
      else
        first_name, last_name = name.split()
      end
    end
    
    first_name.strip! if first_name
    last_name.strip!  if last_name
                          
    person              = Person.new   
    person.first_name   = first_name
    person.last_name    = last_name
    person.contact_list = current_user.contact_list
    person.owner        = current_user
    person.organization = current_organization
    person.save
    
    address = OpenStruct.new
    address.person = person
    address.name   = person.full_name
     
    if email                               
      person.email_addresses.create(:email_type => email_type, :email_address => email)  
      address.mailbox, address.host = email.split('@')
    end

    render :partial => 'mail/imap_address', :locals => {:address => address, :id => -1 }
  end
  
  def create_mailbox
    if params[:parent_id].blank?
      @parent = current_user.inbox
    else
      @parent = current_user.mailboxes.find(params[:parent_id])
    end
    
    @parent.create_child(params[:group_name])
  ensure
    redirect_back_or_home
  end
  
  def rename_group
    @mailbox = Mailbox.find(params[:id], :scope => :edit)
    @mailbox.rename! params[:name]
  ensure
    redirect_back_or_home
  end

  def delete_group
    @mailbox = Mailbox.find(params[:id], :scope => :delete)
    @mailbox.delete!
    redirect_to mail_special_list_url(:id => 'inbox')
  end

  def reply_to
    @view_kind = 'create'
    @original_message = Message.find(params[:id], :conditions => ["messages.active = ?", true], :scope => :read)
    @message = @original_message.build_reply_stub(params[:all])
  rescue ActiveRecord::RecordNotFound
    redirect_to mail_home_url
  end
  
  def forward
    @view_kind = 'create'
    @original_message = Message.find(params[:id], :conditions => ["messages.active = ?", true], :scope => :read)
    @message = @original_message.build_forward_stub
  rescue ActiveRecord::RecordNotFound
    redirect_to mail_home_url
  end
  
  def edit_draft
    @view_kind = 'edit'
    @original_message = Message.find(params[:id], :conditions => ["messages.active = ?", true], :scope => :edit)
    @message = @original_message.build_draft_stub

    respond_to do |wants|
      wants.html { render :action => 'edit_draft' }
      wants.js   { @message = @original_message; render :partial => 'peek' }
    end
  rescue ActiveRecord::RecordNotFound
    redirect_to mail_home_url
  end
  
  def send_draft
    message = Message.find(params[:id], :conditions => ["messages.active = ?", true], :scope => :edit)
    if params[:command] == 'discard'
      redirect_to mail_mailbox_url(:id => message.mailbox_id)
      return
    end
    
    # Build attachments
    new_message = send_mail(:original_message => message)
    message.delete! # Remove the original from drafts
    redirect_to mail_special_list_url(:id => 'inbox')
  rescue ActiveRecord::RecordNotFound
    redirect_to mail_home_url
  end
  
  def send_compose
    send_mail unless params[:command] == 'discard'
    redirect_to mail_special_list_url(:id => 'inbox')
  end
  
  def send_reply_to
    @original_message = Message.find(params[:id], :conditions => ["messages.active = ?", true], :scope => :edit)
    if params[:command] == 'discard'
      redirect_to mail_mailbox_url(:id => @original_message.mailbox_id)
      return
    end
    @original_message.answered!
    new_message = send_mail(:in_reply_to => @original_message.message_id)
    redirect_to mail_special_list_url(:id => 'inbox')
  rescue ActiveRecord::RecordNotFound
    redirect_to mail_home_url
  end
  
  def send_forward
    @original_message = Message.find(params[:id], :conditions => ["messages.active = ?", true], :scope => :edit)
    if params[:command] == 'discard'
      redirect_to mail_mailbox_url(:id => @original_message.mailbox_id)
      return
    end
    @original_message.forwarded!
    new_message = send_mail(:original_message => @original_message)
    redirect_to mail_special_list_url(:id => 'inbox')
  end
  
  def attachment
    message    = Message.find(params[:message], :conditions => ["messages.active = ?", true], :scope => :read)
    attachment = message.attachment(params[:id])
    if params[:inline]
      send_data(attachment.data, :type => attachment.mime_type, :stream => false, :filename => attachment.name, :disposition => 'inline')
    else
      send_data(attachment.data, :type => attachment.mime_type, :stream => false, :filename => attachment.name)
    end
  rescue ActiveRecord::RecordNotFound
    render :nothing => true
  end
  
  def empty_spam
    Mailbox.empty_spam(current_user)
    redirect_to mail_special_list_url(:id => 'spam')
  end

  def inline
    message = Message.find(params[:message], :conditions => ["messages.active = ?", true], :scope => :read)
    part    = message.part_for_id(params[:id])
    if part
      send_data(part, :type => 'image/png', :stream => false, :filename => 'ciordie', :disposition => 'inline')
    else
      render :nothing => true
    end
  rescue ActiveRecord::RecordNotFound
    render :nothing => true
  end
  
  def empty_trash
    Mailbox.empty_trash(current_user)
    redirect_to mail_special_list_url(:id => 'trash')
  end
  
  # this method retrieves each group and smart group [id, name] so Addresses.js can call Ajax
  # and post group_id value for a chosen group or smart group
  def groups_ids
    @groups_ids = current_user.mail_autocomplete_groups
    headers['content-type'] = 'text/javascript'
    render :layout => false
  end
  
  def groups_addresses_for_lookup
    # params[:message] is a hash with 3 possible keys: to_field, cc_field, bcc_field
    @needle = params[:message].values.first.downcase
    # empty searches return nothing, instead of everything
    unless @needle
      render :text => '<ul><li></li></ul>'
      return true
    end
    
    people = Person.find( :all, :include => :email_addresses, :scope => :read,
                          :conditions => ['LOWER(people.first_name) LIKE ? OR
                                           LOWER(people.last_name) LIKE ? OR
                                           LOWER(email_addresses.email_address) LIKE ?', 
                                           "%#{@needle}%", "%#{@needle}%", "%#{@needle}%"])
                                           
    @groups_contacts = current_user.fetch_group_matches(@needle)    
    @groups_contacts << people_emails(people, 'html')      
    @groups_contacts.flatten! 
    render :layout => false  
  end  
  
  def add_group_emails_ajax      
    if params[:group_id] =~ /^pg(\d+)$/
      people = PersonGroup.find(PersonGroup.param_to_id(params[:group_id])).people      
    elsif params[:group_id] =~ /s(\d+)/
      people = SmartGroup.find(SmartGroup.param_to_id(params[:group_id])).items('people.last_name ASC')
    end
    
    emails = people_emails(people, 'json')
    headers['content-type'] = 'text/javascript'
    render :text => emails.to_json
  end
  
  def others_groups
    self.selected_user = User.find(params[:user_id], :scope => :read)
    Mailbox.list(selected_user)
    render :partial => "sidebars/groups/#{@application_name}/others_#{@application_name}"
  end

  def reparent_group
    mailbox = Mailbox.find(params[:group_id], :scope => :move)
    new_parent = current_user.mailboxes.find(params[:new_parent_id], :scope => :create_on)
    mailbox.reparent!(new_parent)
  ensure
    redirect_back_or_home
  end

  def flag
    @message = Message.find(params[:id], :conditions => ["messages.active = ?", true], :scope => :edit)
    @message.flag!
    render :update do |page|
      page["message_flagged_#{@message.id}"].replace_html ''
			page["message_flagged_#{@message.id}"].addClassName 'primaryItem'
      page["message_flagged_#{@message.id}"].removeClassName 'makePrimaryItem'
    end
  rescue ActiveRecord::RecordNotFound
    render :nothing => true
  end
  
  def unflag
    @message = Message.find(params[:id], :conditions => ["messages.active = ?", true], :scope => :edit)
    @message.unflag!
    render :update do |page|
      page["message_flagged_#{@message.id}"].replace_html ''
      page["message_flagged_#{@message.id}"].addClassName 'makePrimaryItem'
			page["message_flagged_#{@message.id}"].removeClassName 'primaryItem'
    end
  rescue ActiveRecord::RecordNotFound
    render :nothing => true
  end

  def inbox_unread_count
    @mailbox = current_user.inbox
    render :text => @mailbox.count.unseen
  rescue
    render :text => '0'
  end

  def notifications
    @view_kind = 'notifications'
    notice_count = current_user.notifications_count('Message', params.has_key?(:all))
    @paginator = Paginator.new self, notice_count, JoyentConfig.page_limit, params[:page]

    if params.has_key?(:all)
      @group_name = 'All Notifications'
      @show_all = true
      @notifications = selected_user.notifications.find(:all, 
                                                        :conditions => ["notifications.item_type = 'Message' "],
                                                        :include    => {:notifier => [:person]},
                                                        :order      => "notifications.created_at DESC",
                                                        :limit      => @paginator.items_per_page, 
                                                        :offset     => @paginator.current.offset)
      @toolbar[:new_notifications] = true
    else
      @group_name = 'Notifications'
      @show_all = false
      @notifications = selected_user.current_notifications.find(:all, 
                                                                :conditions => ["notifications.item_type = 'Message' "], 
                                                                :include    => {:notifier => [:person]},
                                                                :order      => "notifications.created_at DESC",
                                                                :limit      => @paginator.items_per_page, 
                                                                :offset     => @paginator.current.offset)
      @toolbar[:all_notifications] = true
    end

    @toolbar[:compose] = true

    respond_to do |wants|
      wants.html { render :template => 'notifications/list'                        }
      wants.js   { render :partial  => 'reports/notifications', 
                          :locals   => {:show_all => @show_all} }  
    end
  end
  
  # This is probably temporary, if a user has a rich message they feel isn't
  # rendering right, and they consent for us to view it, the raw message will
  # be rolled up and sent to us for analysis.  We can then verify, fix, and
  # anonymize the message.
  def report_issue
    @message = Message.find(params[:id], :conditions => ["messages.active = ?", true], :scope => :read)
    SystemMailer.deliver_report_issue(@message)
    render :text => "Thanks, we'll review your message soon."
  end

  def item_class_name
    'Message'
  end
  
  # Away related methods
  def away_message_edit
    # load this drawer using javascript
    @user = User.find(current_user.id)
    @user.away_message = _("I am away and have limited access to email. I will respond as soon as possible.") if @user.away_message.blank?
    if request.xhr?
      render :partial => 'away'
    else
      redirect_to mail_home_url
      return
    end
  end
  
  def away_message_update
    # just try to update the attributes and hide the drawer on success
    params[:user][:away_on] = params[:user][:away_on] || false
    @user = User.find(current_user.id)
    if request.xhr?
      if @user.update_attributes(params[:user]) 
        render(:update) { |page|
          # How to get access to JavaScript Joyent.effectsDuration from here?
          page.visual_effect(:blind_up, 'drawerAway', :duration => 1)
          page['actionAwayLink'].removeClassName('active');
          # We will try to properly hide/show the info div about the away status
          if @user.away_on?
            page['awayInfo'].show();
            page << "Event.stopObserving($('awayPointerLink'), 'click', awayEvent.listenerLoad);
Event.observe($('awayPointerLink'), 'click', function(event){
return Drawers.toggle('Away');
});"
          else
            page['awayInfo'].hide();
          end
        }
      else
        render(:update) {|page|
          if @user.errors.invalid?(:away_expires_at)
            page.alert("#{@user.errors.on(:away_expires_at)}")
          else
            page.alert(_("We're experiencing some problems now, try again later, please"))
          end
        }
      end
    else
      redirect_to mail_home_url
      return
    end
  end

  #########
  protected
  #########
  
  def current_group_id
    if    @smart_group then @smart_group.url_id
    elsif @mailbox     then @mailbox.id
    elsif @group_name  then @group_name
    else  nil
    end
  end

  def self.group_name
    'Mailbox'
  end
  
  def item_move_url
    mail_message_move_url
  end
  helper_method :item_move_url

  def item_copy_url
    mail_message_copy_url
  end
  helper_method :item_copy_url

  def item_delete_url
    mail_message_delete_url
  end
  helper_method :item_delete_url
  
  # only showing 1 of these at a time for now
  def status_icon(message)
    return '' unless message

    case message.primary_status
    when 'Draft'     then '<img src="/images/icons/edit16Hover.png" title="'+_('Draft')+'" />'
    when 'Read'      then ''
    when 'Replied'   then '<img src="/images/icons/reply.png" title="'+_('Replied')+'" />'
    when 'Forwarded' then '<img src="/images/icons/forward.png" title="'+_('Forwarded')+'" />'
    when 'Flagged'   then '<img src="/images/icons/flag16.png" title="'+_('Flagged')+'" />'
    when 'Junk'      then '<img src="/images/icons/trash.png" title="'+_('Junk')+'" />'
    when 'Spam'      then '<img src="/images/icons2/spam.png" title="'+_('Spam')+'" />'
    when 'Unread'    then '<img src="/images/icons/unread.png" title="'+_('Unread')+'" />'
    else
      '' # should never be needed
    end
  end
  helper_method :status_icon
  
  private
  
    def load_mail_aliases
      @mail_aliases = current_organization.mail_aliases
      unless current_user.admin?
        @mail_aliases = @mail_aliases.select{|ma| ma.membership_for_user(current_user)}
      end
      @mail_alias = @mail_aliases.first
    end

    def send_mail(opts={})
      # FIXME command is coming through blank from send_compose
      params[:message][:from] = "#{current_user.full_name} <#{params[:message][:from]}>"
      opts.merge! :params => params[:message], :user => current_user
    
      case params[:command]
      when 'send'
        data = MailMessage.deliver_joyent_mail(opts)
      when 'save'
        data = MailMessage.save_joyent_mail(opts)
      end
    
      # data is handing back :filename, :joyent_id, :size_in_bytes, :mailbox_id
      # Create a proxy, then tag/comment/permissionize it
      new_msg = Message.create(data.merge({:owner        => current_user,
                                           :organization => current_user.organization}))
    
      params[:new_item_tags].split(',,').each do |tag_name|
        current_user.tag_item(new_msg, tag_name)
      end unless params[:new_item_tags].blank?
      params[:new_item_permissions].split(',').each do |user_dom_id|
        next unless user = find_by_dom_id(user_dom_id)
        new_msg.add_permission(user)
      end unless params[:new_item_permissions].blank?
      params[:new_item_notifications].split(',').each do |user_dom_id|
        next unless user = find_by_dom_id(user_dom_id)
        user.notify_of(new_msg, current_user)
      end unless params[:new_item_notifications].blank?
    
      new_msg.draft! if params[:command] == 'save'
    
      new_msg
    end
    
    def people_emails(people, format)
      emails = []
      # we dont want people without an email address
      people_with_email = people.select{|person| !person.email_addresses.blank?}
      if format.eql? 'html'
        people_with_email.each{ |person|
          for email in person.email_addresses
            emails << "#{person.full_name} \<#{email.email_address}\>"
          end
        }          
      elsif format.eql? 'json'
        people_with_email.each{ |person| emails << {:name => "#{person.first_name} #{person.last_name}", :email => person.primary_email.email_address}}        
      end
      emails
    end

    def redirect_to_mailbox
      case params[:mailbox]
      when /^\d+$/
        redirect_to mail_mailbox_url(:id => params[:mailbox])
      else
        redirect_to mail_special_list_url(:id => params[:mailbox])
      end
    end

    def sync_mailboxes
      @mailboxes    = Mailbox.list(current_user)
      @mailbox_list = current_user.mailboxes
    end
  
    def valid_sort_fields
      ['seen', 'has_attachments', 'sender', 'subject', 'date', 'recipients']
    end

    def default_sort_field
      'date'
    end

    def default_sort_order
      'DESC'
    end
end