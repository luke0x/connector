=begin #(fold)
Copyright 2004-2007 Joyent Inc.

Redistribution and/or modification of this code is governed
by either the GPLv2 or Joyent Commercial Software licenses.

Report issues and contribute at http://dev.joyent.com/

$Id$
=end #(end)

module ApplicationHelper
  
  def item_application(item)
    case item
    when Message    then 'Mail'
    when Event      then 'Calendar'
    when Person     then 'People'
    when JoyentFile then 'Files'
    when Folder     then 'Files'
    when Bookmark   then 'Bookmarks'
    when List       then 'Lists'
    end
  end

  # The order here should be: my folder, others folder
  def item_url(item)
    case item
    when Message
      mail_message_show_url(:id => item.id, :mailbox=>item.mailbox)
    when Event, StubEvent
      if calendar = item.calendars.select{|cal| User.current.id == cal.user_id}.first
        calendar_show_route_url(:id => item.id, :calendar_id => calendar.id)
      else
        calendar_show_route_url(:id => item.id, :calendar_id => item.calendars.first)
      end
    when Person
      person_show_url(:id => item.id)
    when JoyentFile
      files_show_route_url(:id => item.id, :folder_id => item.folder.id)
    when Bookmark
      bookmarks_show_url(:id => item.id)
    when List
      list_url(item)
    else
      logger.info "What are you linking to #{item}"
    end
  rescue => e
    logger.error "ERROR #{e}"
    return "" 
  end

  def peek_url(item, update_id)
    update_id = "#{update_id}_td_details"
    case item
    when Message          then mail_message_show_url(:id => item.id, :mailbox => item.mailbox, :update_id => update_id)
    when Event, StubEvent then calendar_show_route_url(:id => item.id, :calendar_id => item.calendars.first, :update_id => update_id)
    when Person           then person_show_url(:id => item.id, :update_id => update_id)
    when JoyentFile       then files_show_route_url(:id => item.id, :folder_id => item.folder.id, :update_id => update_id)
    when Bookmark         then bookmarks_show_url(:id => item.id, :update_id => update_id)
    when StrongspaceFile  then files_strongspace_show_url(:owner_id => item.owner.id, :path => item.relative_path, :update_id => update_id)
    when ServiceFile      then files_service_show_url(:file_id => item.id, :update_id => update_id)  
    when List             then list_url(:id => item, :update_id => update_id)
    else logger.info "What are you linking to #{item}"
    end
  rescue => e
    logger.error "ERROR #{e}"
    return "" 
  end
  
  def item_modified(item)
    if item.respond_to? :updated_at
      _("%{i18n_time_in_words} ago") % {:i18n_time_in_words => "#{time_ago_in_words(item.updated_at || Time.now)}"}
    else
      ""
    end
  end

  def list_selection_tool
    partial = ''
    partial << '<div id="listCheckboxToggle" class="none" style="text-align: center;">'
    partial << link_to_function(_('Toggle'), "JoyentPage.setItemCheckboxes()", {:title => _('Click to toggle your selection.')})
    partial << '</div>'
    partial
  end

  # returns the link for the th table header, propagating the search string if necessary
  # expects @sort_field and @sort_order to be set already
  def toggle_sort_th(title, field, th_class = '', a_html_options = {})
    partial = ''

    if @sort_field == field
      new_sort_order = @sort_order == 'ASC' ? 'DESC' : 'ASC'
      th_class << (new_sort_order == 'ASC' ? ' listedByDescending' : ' listedByAscending')
    else
      new_sort_order = 'ASC'
      th_class << ' unsorted'
    end

    url_options = { :action => :set_sort_order, :sort_field => field, :sort_order => new_sort_order }

    partial << "<th class=\"#{th_class}\">"
    partial << link_to(title, url_options, a_html_options)
    partial << '</th>'
    partial
  end

  def render_default_group(partial_path, partial_locals = {})
    raise "Default group partial can not be blank" if partial_path.blank?

    partial_locals[:subscription] = partial_locals.has_key?(:subscription) ? partial_locals[:subscription] : false

    new_locals = {}
    new_locals[:icon_class]             = partial_locals[:icon_class] || 'group'
    new_locals[:default_group_name]     = partial_locals[:name]       || 'Default Group'
    # need a better way to do this if we're going to do this elsewhere
    if @application_name == 'mail' && partial_locals[:name] =~ /#{_('Inbox')}/
      new_locals[:default_group_name] = '<span id="inbox_name_and_count">' + partial_locals[:name] + '</span>'
    end
    new_locals[:default_group_url]      = partial_locals[:url]        || ''
    new_locals[:default_group_selected] = partial_locals[:selected]   || false
    new_locals[:subscription]           = partial_locals[:subscription]
    new_locals[:content]                = new_locals[:default_group_selected] ? (render :partial => partial_path, :locals => partial_locals) : ''

    render :partial => 'sidebars/groups/default_group', :locals => new_locals
  end

  def render_standard_group(partial_path, partial_locals = {})
    raise "Standard group partial can not be blank" if partial_path.blank?

    partial_locals[:subscription] = partial_locals.has_key?(:subscription) ? partial_locals[:subscription] : false

    new_locals = {}
    new_locals[:partial_path]            = partial_path
    new_locals[:level]                   = partial_locals[:level]      || 0
    new_locals[:css_class]               = partial_locals.has_key?(:css_class) ? partial_locals[:css_class] : 'group'
    new_locals[:standard_group]          = partial_locals[:standard_group]
    new_locals[:standard_group_url]      = partial_locals[:url]        || ''
    new_locals[:standard_group_selected] = partial_locals[:selected_group]
    new_locals[:skip_children]           = partial_locals.has_key?(:skip_children) ? partial_locals[:skip_children] : false
    new_locals[:others]                  = partial_locals.has_key?(:others) ? partial_locals[:others] : false # TODO: still used?
    new_locals[:subscription]            = partial_locals[:subscription]
    new_locals[:content]                 = new_locals[:standard_group_selected] ? (render :partial => partial_path, :locals => partial_locals) : ''
    new_locals[:selected]                = partial_locals[:selected_group] &&
                                           (partial_locals[:standard_group] == partial_locals[:selected_group]) &&
                                           ((! new_locals[:others]) or (new_locals[:others] and ! User.current.subscribed_to?(new_locals[:standard_group])))
    new_locals[:name]                    = partial_locals[:name] || new_locals[:standard_group].name
    if @application_name == 'mail' and new_locals[:name] == 'INBOX'
      new_locals[:name] = 'Inbox'
    end
    render :partial => 'sidebars/groups/standard_group', :locals => new_locals
  end

  def render_strongspace_group(partial_path, partial_locals = {})
    raise "Strongspace group partial can not be blank" if partial_path.blank?

    partial_locals[:subscription] = partial_locals.has_key?(:subscription) ? partial_locals[:subscription] : false

    new_locals = {}
    new_locals[:partial_path]            = partial_path
    new_locals[:level]                   = partial_locals[:level]      || 0
    new_locals[:css_class]               = partial_locals.has_key?(:css_class) ? partial_locals[:css_class] : 'strongspace'
    new_locals[:standard_group]          = partial_locals[:standard_group]
    new_locals[:standard_group_url]      = partial_locals[:url]        || ''
    new_locals[:standard_group_selected] = partial_locals[:selected_group]
    new_locals[:skip_children]           = partial_locals.has_key?(:skip_children) ? partial_locals[:skip_children] : false
    new_locals[:others]                  = partial_locals.has_key?(:others) ? partial_locals[:others] : false
    new_locals[:subscription]            = partial_locals[:subscription]
    new_locals[:content]                 = new_locals[:standard_group_selected] ? (render :partial => partial_path, :locals => partial_locals) : ''
    
    render :partial => 'sidebars/groups/strongspace_group', :locals => new_locals
  end

  def render_service_group(partial_path, partial_locals = {})
    raise "Service group partial can not be blank" if partial_path.blank?

    partial_locals[:subscription] = partial_locals.has_key?(:subscription) ? partial_locals[:subscription] : false

    new_locals = {}
    new_locals[:partial_path]            = partial_path
    new_locals[:level]                   = partial_locals[:level]      || 0
    new_locals[:css_class]               = partial_locals.has_key?(:css_class) ? partial_locals[:css_class] : 'group'
    new_locals[:standard_group]          = partial_locals[:standard_group]
    new_locals[:standard_group_url]      = partial_locals[:url]        || ''
    new_locals[:standard_group_selected] = partial_locals[:selected_group]
    new_locals[:skip_children]           = partial_locals.has_key?(:skip_children) ? partial_locals[:skip_children] : false
    new_locals[:others]                  = partial_locals.has_key?(:others) ? partial_locals[:others] : false
    new_locals[:subscription]            = partial_locals[:subscription]
    new_locals[:content]                 = new_locals[:standard_group] == new_locals[:standard_group_selected] ? (render :partial => partial_path, :locals => partial_locals) : ''
    new_locals[:service_name]            = new_locals[:standard_group].service.name
    
    render :partial => 'sidebars/groups/service_group', :locals => new_locals
  end

  def render_smart_group(partial_path, partial_locals = {})
    raise "Smart group partial can not be blank" if partial_path.blank?

    new_locals = {}
    new_locals[:partial_path]         = partial_path
    new_locals[:icon_class]           = partial_locals[:icon_class] || ''
    new_locals[:smart_group]          = partial_locals[:smart_group]
    new_locals[:smart_group_selected] = partial_locals[:selected_group]
    new_locals[:content]              = new_locals[:smart_group_selected] ? (render :partial => partial_path, :locals => partial_locals) : ''

    render :partial => 'sidebars/groups/smart_group', :locals => new_locals
  end

  # the drop-down for the smart group's boolean mode
  def smart_group_boolean_mode_select(mode = 'all')
#    modes = { "All" => "all", "Any" => "any" }
#    partial = ''
#    partial << 'Match '
#    partial << '<select name="boolean_mode" size="1" style="font-size:9px; width: 50px;">'
#    partial << options_for_select(modes.sort{|a, b| a[1] <=> b[1]}, mode)
#    partial << '</select>'
#    partial << ' Conditions:'
#    partial
    # temporary fix re: case 2796
    _('Match All: ')
  end

  # options can either be a hash to compute a url, or a string for the action url
  # TODO: needs to be kept ~in sync with the rails image_tag method
  def image_tag_from_route(options, tag_options = {})
    tag_options.symbolize_keys

    if options.is_a?(Hash)
      tag_options[:src] = url_for(options)
    elsif options.is_a?(String)
      tag_options[:src] = "#{options}?#{Time.now.to_i.to_s}"
    else
      raise "Invalid options class"
    end

    if tag_options[:size]
      tag_options[:width], tag_options[:height] = tag_options[:size].split("x")
      tag_options.delete :size
    end

    tag("img", tag_options)
  end

  # a select box for selecting the parent of the currently selected standard group
  def standard_groups_select_field(selected_group)
    partial = ''
    partial << '<select name="new_parent_id" id="new_parent_id" size="1" style="margin: 3px 0; width: 120px;">'
      partial << "<option #{selected_group.parent.blank? ? 'selected="selected"' : ''} #{@application_name == 'lists' ? 'value="' + User.current.lists_list_folder.id.to_s + '"' : ''}>"
        partial << _('Top Level')
      partial << '</option>'

      # okay, this is ~HAX
      roots = case @application_name
      when 'mail'      then User.current.mail_root_mailboxes
      when 'calendar'  then User.current.calendar_root_calendars
      when 'people'    then []
      when 'files'     then User.current.files_root_folders
      when 'bookmarks' then []
      when 'lists'     then User.current.lists_root_folders
      else
        []
      end

      roots.each do |root|
        partial << options_for_group(root, selected_group) unless root == selected_group
      end
    partial << '</select>'
    partial
  end

  def strongspace_groups_select_field(selected_group)
    partial = ''
    partial << '<select name="new_parent_path" id="new_parent_id" size="1" style="margin: 3px 0; width: 120px;">'
      if selected_group.parent.blank?
        partial << '<option selected="selected" value="">'
      else
        partial << '<option value="">'
      end
        partial << _('Top Level')
      partial << '</option>'

      # okay, this is ~HAX
      roots = [User.current.strongspace_folder]

      roots.each do |root|
        partial << options_for_strongspace_group(root, selected_group) unless root == selected_group
      end
    partial << '</select>'
    partial
  end

  # recursively create a flat list of indented options
  def options_for_group(group, selected_group, level = 1)
    return '' unless group

    prefix = "- "

    partial = ''
    if group.children.include?(selected_group)
      partial << '<option selected="selected" value="' + group.id.to_s + '">'
    else
      partial << '<option value="' + group.id.to_s + '">'
    end
      partial << prefix * level
      partial << group.name
    partial << '</option>'

    group.children.each do |child|
      partial << options_for_group(child, selected_group, level + 1) unless child == selected_group
    end
    partial
  end

  def options_for_strongspace_group(group, selected_group, level = 1)
    return '' unless group

    prefix = "- "

    partial = ''
    if group.children.include?(selected_group)
      partial << '<option selected="selected" value="' + group.relative_path + '">'
    else
      partial << '<option value="' + group.relative_path + '">'
    end
      partial << prefix * level
      partial << group.name
    partial << '</option>'

    group.children.each do |child|
      partial << options_for_strongspace_group(child, selected_group, level + 1) unless child == selected_group
    end
    partial
  end


  # i18n: this needs a review; anyway, it will works if approximate is not used
  # 3720 => '1 hour 2 minutes'
  def duration_in_words(seconds)
    out = []
    approximate = false

    # can include other windows such as 'year' or 'month'
    ['hour', 'minute'].each do |window|
      if seconds / 1.send(window) > 0
        out << pluralize(seconds / 1.send(window), _(window))
        seconds -= (seconds / 1.send(window)).send(window)
        approximate = true if window == 'month'
      end
    end

    approximate ? 'About ' + out.join(' ') : out.join(' ')
  end
  
  def rss_date_for(model)
    if model.updated_at
      model.updated_at.httpdate
    else
      model.created_at.httpdate
    end
  end

  def flash_message(flash_key = :error)
    if flash[flash_key]
      "<span class=\"flash_error\">#{flash[flash_key]}</span>"
    else
      ''
    end
  end

  def format_date(time)
    time.strftime("%A %B %d, %Y").gsub(/ 0(\d)/, ' \1') if time
  end
  
  def format_time(time)
    time.strftime('%I:%M %p').gsub(/^0(\d)/, '\1') if time
  end
  
  # i18n: Maybe use constants for date and time format strings
  # this is just a trick which will work with Spanish
  def format_date_time(time, long=true)
    return nil unless time
    
    long ? time.strftime("%A %B %d, %Y "+_('at')+" %I:%M %p").gsub(/ 0(\d)/, ' \1') : time.strftime('%m/%d/%Y %I:%M%p').gsub(/ 0(\d)/, ' \1').gsub(/^0(\d)/, '\1').downcase
  end
             
  def localize_time(time)
    if User.current && time
      User.current.person.tz.utc_to_local(time)
    else
      time
    end
  end
  
  def normalize_time(time)
    if User.current && time
      User.current.person.tz.local_to_utc(time)
    else
      time
    end
  end     
  
  # formats the date in words if time is newer than 5 days
  # othwerwise it formats it like the OS X's Finder default-style
  def format_local_words_or_date(time)
    if localize_time(5.days.ago) < localize_time(time)
      _("%{i18n_time_in_words} ago") % {:i18n_time_in_words => time_ago_in_words(time)}
    else
      localize_time(time).strftime("%b %d, %Y, %I:%M %p")
    end
  end  

  def hierarchical_groups_select(options = {})
    return '' unless options.has_key?(:id)
    return '' unless options.has_key?(:name)
    return '' unless options.has_key?(:groups)
    return '' unless options.has_key?(:selected)
    html = ''

    def hierarchical_groups_options(option_options = {})
      return '' unless option_options.has_key?(:depth)
      return '' unless option_options.has_key?(:selected)
      return '' unless option_options.has_key?(:groups)
      return '' unless option_options[:groups]
      html = ''

      option_options[:groups].each do |group|
        html << "<option value=\"#{group.id}\" #{'selected=\"selected\"' if group == option_options[:selected]}>"
        html << "- " * option_options[:depth]
        html << group.name
        html << '</option>'
        if group.respond_to?(:children)
          html << hierarchical_groups_options(:groups => group.children, :depth => option_options[:depth] + 1, :selected => option_options[:selected])
        end
      end

      html
    end

    html << "<select id=\"#{options[:id]}\" name=\"#{options[:name]}\">"
		html << '<optgroup>'
		html << hierarchical_groups_options(:groups => options[:groups], :depth => 0, :selected => options[:selected])
		html << '</optgroup>'
		html << '</select>'
		html
  end

  def google_maps_link(address)
    url = 'http://maps.google.com/maps?q=' + address.url_encoded_geocode_address
    link_to _('Map'), url, { :target => '_blank', :title => _('Look up address in Google Maps'), :class => 'go toGoogle' }
  end

  def select_tag_with_id(name, option_tags = nil, options = {})
    tag_id = options.has_key?(:id) ? options[:id] : name
    content_tag :select, option_tags, { "name" => name, "id" => tag_id }.update(options.stringify_keys)
  end

  def svn_version
    return '' unless ENV['SHOW_VERSION_IN_OUTPUT']
    version = YAML::load(`svn info`)['Revision'] rescue 'Unknown'
    "<!-- Joyent Connecter rev. #{version} -->"
  end

  def group_parameter
    raise "Application must implement this method"
  end

  # TODO: dry this up with a convention
  def item_image_class(item)
    case item
    when Message    then 'mail'
    when Event      then 'calendar'
    when Person     then 'peep'
    when JoyentFile then 'files'
    when Bookmark   then 'bookmark'
    when List       then 'list'
    else
      ''
    end
  end

  def javascript_jsar_init(items, view_kind)
    return '' unless items
    out = []
    selected = ['create', 'show', 'edit'].include?(view_kind)
    
    taggings = items.collect(&:taggings).flatten.uniq
    tags = taggings.collect(&:tag).uniq

    items.each do |item|
      out << item_to_jsar(item, selected)
      item.permissions.each do |permission|
        out << permission_to_jsar(permission)
      end unless item.public?
      item.active_notifications.each do |notification|
        out << notification_to_jsar(notification)
      end
    end
    taggings.each do |tagging|
      out << tagging_to_jsar(tagging)
    end
    tags.each do |tag|
      out << tag_to_jsar(tag)
    end
    out << user_to_jsar(User.current)
    User.current.other_users.each do |user|
      out << user_to_jsar(user)
    end

    out.join("\n")
  end      
  
  def add_to_workspace(report_description_name, reportable)
    report_description = ReportDescription.find_by_name(report_description_name.to_s)
    report             = report_description.reports.find_by_user_id_and_reportable_id(User.current.id, reportable.id)
    check_box_action(_("Visible in your Workspace"),
                     !report.blank?,
                     reports_create_url(:report_description_id => report_description, :reportable_id => reportable),
                     reports_destroy_by_desc_url(:report_description_id => report_description, :reportable_id => reportable)
                    )
  end
  
  def check_box_action(text, is_checked, checked_url, unchecked_url)
    "<input type=\"checkbox\" onchange=\"performCheckboxToggleAction(this, '#{checked_url}' , '#{unchecked_url}');\" #{'checked="checked"' if is_checked} /> #{text}"
  end

  def javascript_current_user_tags
    return '' if User.current.tags.blank?
    out = []
    
    User.current.tags.each do |tag|
      out << tag_to_jsar(tag)
    end

    out.join("\n")
  end

  def render_list_header(title, paginator, item_kind)
    raise "Header title can not be blank" if title.blank?

    new_locals = {}
    new_locals[:title]     = title
    new_locals[:paginator] = paginator
    new_locals[:item_kind] = item_kind
    u = controller.request.env['REQUEST_PATH'].to_s
    q = controller.request.env['QUERY_STRING'].to_s
    p = paginator.current_page.number
    new_locals[:prev_url] = p > 1 ? url_merge(u, q, {'page' => (p - 1)}) : ''
    new_locals[:next_url] = paginator.page_count > p ? url_merge(u, q, {'page' => (p + 1)}) : ''
    new_locals[:jump_url] = url_merge(u, q, {'page' => 'jump_url_page_number'})

    render :partial => 'partials/list_header', :locals => new_locals
  end

  def url_merge(url, query, query_merge = {})
    out = ''
    out << url

    query = query.split('&')
    query = query.inject({}){|h,v| v = v.split('='); h[v[0]] = v[1]; h}
    query.merge!(query_merge)

    out << '?' unless query.blank?
    out << query.to_a.collect{|a| a.join('=')}.join('&')

    out
  end

  def render_show_header(title, paginator, item_kind)
    raise "Header title can not be blank" if title.blank?

    new_locals = {}
    new_locals[:title]     = title
    new_locals[:paginator] = paginator
    new_locals[:item_kind] = item_kind
    new_locals[:prev_url] = if paginator.current_page.number > 1
      message_index = 0
      @messages.each{|message| break if message == @message; message_index += 1;}
      message = @messages[message_index - 1]
      item_url(message)
    else
      ''
    end
    new_locals[:next_url] = if paginator.page_count > paginator.current_page.number
      message_index = 0
      @messages.each{|message| break if message == @message; message_index += 1;}
      message = @messages[message_index + 1]
      item_url(message)
    else
      ''
    end

    render :partial => 'partials/show_header', :locals => new_locals
  end
  
  # i18n: ensure get proper language code from the available ones list
  # def lang_code(textdomain, path = nil)
  #   unless User.current.blank?
  #     user_language = User.current.get_option('Language')
  #     return user_language unless user_language.blank? or user_language == 'Automatic'
  #   end
  # 
  #   path ||= '/locale/%{locale}/LC_MESSAGES/%{name}.mo'
  #   locale_path = File.join(File.expand_path(RAILS_ROOT), path)
  #   mofile = locale_path % {:locale => GetText.locale.language, :name => textdomain }
  #   MockFS.file.exist?(mofile) ? GetText.locale.language : 'en'
  # end
  
  # use :button_class to set a class for an icon on the button
  def joyent_button_to(name, options = {}, html_options = nil, *parameters_for_method_reference)
    html_options ||= {}
    html_options[:class] ||= ''
    html_options[:class] += ' buttonStandard'

    name = '<div class="buttonStandardLeft"><div class="buttonStandardRight"><div class="buttonStandardBG"><span class="' + html_options[:button_class].to_s + '">' + name + '</span></div></div></div>'
    
    link_to name, options, html_options, *parameters_for_method_reference
  end

  # use :button_class to set a class for an icon on the button
  def joyent_button_to_function(name, *args, &block)
    html_options = args.last.is_a?(Hash) ? args.pop : {}
    function = args[0] || ''
    html_options[:class] ||= ''
    html_options[:class] += ' buttonStandard'

    name = '<div class="buttonStandardLeft"><div class="buttonStandardRight"><div class="buttonStandardBG"><span class="' + html_options[:button_class].to_s + '">' + name + '</span></div></div></div>'
    
    link_to_function name, function, html_options, &block
  end
  
  # use :button_class to set a class for an icon on the button
  def joyent_button_to_remote(name, options = {}, html_options = {})
    html_options[:class] ||= ''
    html_options[:class] += ' buttonStandard'
    html_options[:button_class] ||= ' noIcon'

    name = '<div class="buttonStandardLeft"><div class="buttonStandardRight"><div class="buttonStandardBG"><span class="' + html_options[:button_class].to_s + '">' + name + '</span></div></div></div>'
    
    link_to_remote name, options, html_options
  end
  
  # Browser stuff
  
  def browser_title
    session[:browser_context].capitalize
  end
  
  def render_initial_column(params)
    next_type = ''
    case session[:browser_context]
    when 'subscribe'
      next_type = params[:app] ? 'group' : 'app'
      params[:type] = 'org'
      browsable = Browsable.new(params, User.current)
    when 'move', 'copy'  
      next_type = 'view'
      if params[:view]
        params[:type] = 'view'
        browsable = Browsable.new(params, User.current)
      else
        params[:type] = 'group'
        browsable = Browsable.new(params, User.current)
      end
    end  
    render :partial => 'browser/columns', :locals => { :params => params, :items => browsable.items, :next_type => next_type }
  end
  
  def column_id(params)
    if params[:subscribable_id]
      "#{params[:type]}_column_#{CGI::escape(params[:subscribable_id])}"
    else
      "#{params[:type]}_column"
    end
  end
  
  def icon_class(item)
    "browser#{item}"
  end
  
  def remote_column_link(text, params, item)
    url = browse_column_url(params)
    link_to_remote "#{text}",
			{ :url => url,
			  :loading => "browser.browseLoading('#{params[:current_column]}');",
			  :complete => "browser.browseComplete('#{params[:current_column]}');",
			  :before => "browser.browseBefore('#{params[:current_column]}');browser.makeSelected('#{item.dom_id}', '#{params[:subscribable_id]}');" },
			{ :title => item.link_text }
  end
  
  def remote_subscription(options={})
    if options[:subscribable_type].nil? #in-case there are no subscribable groups
      render :partial => 'disabled_button', :locals => {:text => 'None Found'}
    elsif User.current.subscribed_to?(nil, options[:subscribable_type], options[:subscribable_id])
      render :partial => 'disabled_button', :locals => {:text => 'Subscribed'}
    else
      options[:url] = subscription_create_url(:subscribable_id => options[:subscribable_id], 
                         :subscribable_type => options[:subscribable_type],
                         :organization_id => User.find(options[:user_id]).organization.id,
                         :user_id => User.current.id, :escape => false)
      # MOVE THIS TO NEW METHOD ABOVE               
      link_to_remote '<div class="buttonStandardLeft" id="subscribe"><div class="buttonStandardRight"><div class="buttonStandardBG">'+_('Subscribe')+' ' + '</div></div></div>',
                  { :url => options[:url],
                    :loading => "browser.subscribeLoading();",
      						  :complete => "browser.subscribeFinish();" }, { :class => '', :style => 'width:11em; display:block;' }
    end
  end
   
  def render_cancel_button(params={})
    case session[:browser_context]
    when 'subscribe' then joyent_button_to_function _('Cancel'), "JoyentPage.hideEverything();", {:style => 'width: 7em;'}
    when 'move', 'copy' then joyent_button_to_function _('Cancel'), "Drawers.toggleBrowser('#{session[:browser_context].capitalize}');", {:style => 'width: 7em;'}
    end
  end
  
  def render_action_button(params={}, on=false, page=nil)
    case session[:browser_context]
    when 'subscribe'
      if on
        page.replace_html 'browser_action_button', remote_subscription( :subscribable_id => params[:subscribable_id], 
                                                    									  :subscribable_type => params[:subscribable_type],
                                                    									  :user_id => params[:user_id] )
      else
        render_disabled_button('Subscribe')
      end
    when 'move'
      if on
        page.replace_html 'browser_action_button', joyent_button_to_function( _(session[:browser_context].capitalize),
                                                                  "browser.submitAction('toolbarMoveForm', function() { return Toolbar.moveSubmit('toolbarMoveForm'); })",
                                                      						{ :class => '', 
                                                      						  :style => 'width:11em; display:block;',
                                                      						  :title => 'Move selected items' } )
      else
        render_disabled_button('Move')
      end
    when 'copy'
      if on
        page.replace_html 'browser_action_button', joyent_button_to_function( _(session[:browser_context].capitalize),
                                                                  "browser.submitAction('toolbarCopyForm', function() { return Toolbar.copySubmit('toolbarCopyForm'); })",
                                                      						{ :class => '', 
                                                      						  :style => 'width:11em; display:block;',
                                                      						  :title => 'Copy selected items' } )
      else
        render_disabled_button('Copy')
      end
    end
  end
  
  def render_disabled_button(text)
    render :partial => 'browser/disabled_button', :locals => {:text => text}
  end
  
  def joyent_javascript_include_tags
    js = []
    js << javascript_include_tag("lang/#{User.current.language}")
    if RAILS_ENV == 'production'
    	js << javascript_include_tag('all')
    else
      ['prototype', 'builder', 'effects', 'dragdrop', 'controls', 'joyent_prototype', 'jsar', 'lightbox', 'application', 'ui_elements', 'sidebar', 'browser', 'toolbar', 'group', 'smart_group'].each do |j|
        js << javascript_include_tag(j)
      end
    end
  	js << javascript_include_tag(@application_name)
  	if ['reports', 'connect'].include?(controller.controller_name) and @application_name != 'calendar'
      js << javascript_include_tag('calendar')
  	end
  	js.join("\n")
  end
  
  def joyent_stylesheet_link_tags
    css = []
    if RAILS_ENV == 'production'
      css << stylesheet_link_tag('all')
    else
      ['item', 'tools', 'apps', 'forms', 'sidebars', 'browser', 'drawers', 'icons', 'master', 'lightbox'].each do |c|
        css << stylesheet_link_tag(c)
      end
    end
  	css << stylesheet_link_tag(Organization.current.affiliate.name)
  	css << stylesheet_link_tag(@application_name)
  	css << stylesheet_link_tag("lang/#{User.current.language}/#{User.current.language}-#{@application_name}")
  	css << stylesheet_link_tag("lang/#{User.current.language}/#{User.current.language}")
  	if ['reports', 'connect'].include?(controller.controller_name)
  	  ['mail', 'calendar', 'people', 'files', 'bookmarks', 'lists'].each do |app_name|
    	  css << stylesheet_link_tag(app_name) unless (@application_name == app_name)
  	  end
  	end
  	css << '<!--[if IE 6]>'
		css << stylesheet_link_tag('ie6')
  	css << '<![endif]-->'
  	css << '<!--[if IE 7]>'
	  css << stylesheet_link_tag('ie7')
  	css << '<![endif]-->'
  	css.join("\n")
  end
  
end
