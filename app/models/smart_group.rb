=begin #(fold)
Copyright 2004-2007 Joyent Inc.

Redistribution and/or modification of this code is governed
by either the GPLv2 or Joyent Commercial Software licenses.

Report issues and contribute at http://dev.joyent.com/

$Id$
=end #(end)

class SmartGroup < ActiveRecord::Base
  include RestrictedFind

  validates_presence_of :name
  validates_presence_of :smart_group_description_id
  validates_presence_of :user_id
  validates_presence_of :organization_id
  
  has_many   :smart_group_attributes, :dependent => :destroy
  has_many   :reports, :dependent => :destroy, :as => :reportable 
  belongs_to :smart_group_description
  belongs_to :owner, :class_name => 'User', :foreign_key => 'user_id'
  belongs_to :organization

  serialize :tags # Any other serialize calls require signed waivers
  
  # localization
  untranslate_all

  def url_id
    "s#{self.id}"
  end

  # PDI: we need to take into consideration the sort with the pagination.
  def items(order = nil, limit = nil, offset = nil)
    case application_name
    when 'connect'   then get_app_items(nil, order, limit, offset)
    when 'mail'      then get_app_items(Message, order, limit, offset)
    when 'files'     then get_app_items(JoyentFile, order, limit, offset)
    when 'calendar'  then get_app_items(Event, order, limit, offset)
    when 'people'    then get_app_items(Person, order, limit, offset)
    when 'bookmarks' then get_app_items(Bookmark, order, limit, offset)
    when 'lists'     then get_app_items(List, order, limit, offset)
    else
      raise 'unrecognized app name'
    end || []
  end
  
  def items_count
    case application_name
    when 'connect'   then get_app_items(nil, nil, nil, nil, true)
    when 'mail'      then get_app_items(Message, nil, nil, nil, true)
    when 'files'     then get_app_items(JoyentFile, nil, nil, nil, true)
    when 'calendar'  then get_app_items(Event, nil, nil, nil, true)
    when 'people'    then get_app_items(Person, nil, nil, nil, true)
    when 'bookmarks' then get_app_items(Bookmark, nil, nil, nil, true)
    when 'lists'     then get_app_items(List, nil, nil, nil, true)
    else
      raise 'unrecognized app name'
    end
  end
  
  def application_name
    case smart_group_description.item_type
    when nil          then 'connect'
    when 'Message'    then 'mail'
    when 'Event'      then 'calendar'
    when 'Person'     then 'people'
    when 'JoyentFile' then 'files'
    when 'Bookmark'   then 'bookmarks'
    when 'List'       then 'lists'
    else
      raise "Unknown item type '#{smart_group_description.item_type}'"
    end
  end
  
  def controller
    Object.const_get "#{application_name.capitalize}Controller"
  end
  
  # turns s17 into 17
  def self.param_to_id(smart_group_id)
    smart_group_id.sub(/^s/, '')
    # /s(\d+)/.match(smart_group_id)[1]
  end

  def self.create_from_search(needle)
    raise "Invalid needle" if needle.blank?
    raise "No user" if User.current.blank?
    raise "No organization" if Organization.current.blank?
    
    sgd = SmartGroupDescription.find_by_name('All Items')

    smart_group = SmartGroup.new do |sg|
      sg.owner                   = User.current
      sg.organization            = Organization.current
      sg.name                    = _("Search for %{i18n_search_param}")%{:i18n_search_param => "'#{needle}'"}
      sg.smart_group_description = sgd
      sg.accept_any              = false
      sg.tags                    = []
    end
    smart_group.save

    sgad = sgd.smart_group_attribute_descriptions.find_by_name('Any Condition')
    smart_group.smart_group_attributes.create(:smart_group_attribute_description_id => sgad.id, :value => needle)

    smart_group
  end
  
  def self.create_from_params(params)
    smart_group = SmartGroup.new do |sg|
      sg.owner                      = User.current
      sg.organization               = Organization.current
      sg.name                       = params[:smart_group_name] if params[:smart_group_name]
      sg.smart_group_description_id = params[:smart_group_description_id]
      sg.accept_any                 = false
      sg.tags                       = params[:tag] ? params[:tag].collect{|k,v| v} : []
    end
    smart_group.save

    params[:attribute].each do |index, attribute|
      smart_group.smart_group_attributes.create(:smart_group_attribute_description_id => attribute[:key], :value => attribute[:value])
    end if params[:attribute]

    smart_group
  end
  
  def update_from_params(params)
    self.name       = params[:smart_group_name] if params[:smart_group_name]
    self.accept_any = false
    self.tags       = params[:tag] ? params[:tag].collect{|k,v| v} : []
    self.save

    smart_group_attributes.clear
    params[:attribute].each do |index, attribute|
      self.smart_group_attributes.create(:smart_group_attribute_description_id => attribute[:key], :value => attribute[:value])
    end if params[:attribute]

    self
  end
  
  #######
  private
  #######

  VALID_FIELDS = {
    'connect' => {
      'owner_name' => 'users.username'
    },
    'mail' => {
      'owner_name' => 'users.username',
      'from' => 'messages.sender',
      'to' => 'messages.recipients',
      'subject' => 'messages.subject',
      'date' => 'messages.date',
      'status' => 'messages.status'
    },
    'calendar' => {
      'location' => 'events.location',
      'notes' => 'events.notes',
      'owner_name' => 'users.username',
      'name' => 'events.name',
      'recurrence_name' => 'events.recurrence_name'
    },
    'people' => {
      'first_name' => 'people.first_name',
      'company_name' => 'people.company_name',
      'full_name' => 'users.full_name',
      'last_name' => 'people.last_name',
      'owner_name' => 'users.username'
    },
    'files' => {
      'filename' => 'joyent_files.filename',
      'owner_name' => 'users.username'
    },
    'bookmarks' => {
      'uri' => 'bookmarks.uri',
      'title' => 'bookmarks.title',
      'owner_name' => 'users.username',
      'notes' => 'bookmarks.notes'
    },
    'lists' => {
      'owner_name' => 'users.username'
    }
  }

  def get_app_items(item_class, order, limit, offset, just_count = false)
    conditions = []
    conditions_values = []
    include_parameters = [:owner, :tags]

    smart_group_attributes.each do |sga|
      # In mysql LIKE is case insensitive unless the comparison or the pattern is BINARY
      if VALID_FIELDS[application_name].has_key?(sga.attribute_name)
        conditions << "#{VALID_FIELDS[application_name][sga.attribute_name]} LIKE ?"
        conditions_values << "%#{sga.value}%"
      elsif sga.smart_group_attribute_description.body
        tmp = '('
        tmp << VALID_FIELDS[application_name].values.collect do |key|
          conditions_values << "%#{sga.value}%"
          "#{key} LIKE ?"
        end.join(' OR ')
        tmp << ')'
        conditions << tmp
      end
    end

    if ! tags.blank? and ! tags.empty?
      conditions << "tags.name IN (?)"
      conditions_values << tags
    end

    if item_class == Message
      conditions << "messages.active = TRUE"
      conditions << "mailboxes.full_name != 'INBOX.Trash'"
      include_parameters << :mailbox
    end

    conditions = conditions.join(' AND ')

    if application_name == 'connect'
      available_item_classes = [Message, Event, Person, JoyentFile, Bookmark, List]
      item_classes = []

      # catch the possible empty query where multiple item types are specified
      return (just_count ? 0 : []) if smart_group_attributes.select{|sga| sga.attribute_name == 'item_type'}.length > 1
      
      smart_group_attributes.select{|sga| sga.attribute_name == 'item_type'}.each do |sga|
        if available_item_classes.map(&:to_s).include?(sga.value)
          item_classes << Object.const_get(sga.value)
        else
          return (just_count ? 0 : [])
        end
      end
      item_classes.uniq!
      item_classes = available_item_classes if item_classes.empty?
      if just_count
        item_classes.inject(0) do |count, item_class|
          actual_conditions = conditions.clone
          actual_conditions_values = conditions_values.clone
          actual_include_parameters = include_parameters.clone
          if item_class == Message
            actual_conditions << " AND " unless actual_conditions.blank?
            actual_conditions << "messages.active = TRUE AND mailboxes.full_name != 'INBOX.Trash'"
            actual_include_parameters << :mailbox
          end
          if actual_conditions.blank?
            count += item_class.restricted_count(:all, :include => actual_include_parameters)
          else
            count += item_class.restricted_count(:all, :conditions => [actual_conditions] + actual_conditions_values, :include => actual_include_parameters)
          end
        end
      else
        items = item_classes.inject([]) do |arr, item_class|
          actual_conditions = conditions.clone
          actual_conditions_values = conditions_values.clone
          actual_include_parameters = include_parameters.clone
          if item_class == Message
            actual_conditions << " AND " unless actual_conditions.blank?
            actual_conditions << "messages.active = TRUE AND mailboxes.full_name != 'INBOX.Trash'"
            actual_include_parameters << :mailbox
          end
          if actual_conditions.blank?
            items = item_class.find(:all, :include => actual_include_parameters, :scope => :org_read)
          else
            items = item_class.find(:all, :conditions => [actual_conditions] + actual_conditions_values, :include => actual_include_parameters, :scope => :org_read)
          end
          arr.concat(items)
        end
        items = items.sort_by(&:updated_at).reverse unless items.empty?
        items = items[offset, limit] unless offset.blank? or limit.blank?
        items
      end
    else
      if just_count
        if conditions.blank?
          item_class.restricted_count(:all, :include => include_parameters)
        else
          item_class.restricted_count(:all, :conditions => [conditions] + conditions_values, :include => include_parameters)
        end
      else
        if conditions.blank?
          item_class.find(:all, :order => order, :limit => limit, :offset => offset, :include => include_parameters, :scope => :org_read)
        else
          item_class.find(:all, :conditions => [conditions] + conditions_values, :order => order, :limit => limit, :offset => offset, :include => include_parameters, :scope => :org_read)
        end
      end
    end
  end

end