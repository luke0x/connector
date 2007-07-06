=begin #(fold)
Copyright 2004-2007 Joyent Inc.

Redistribution and/or modification of this code is governed
by either the GPLv2 or Joyent Commercial Software licenses.

Report issues and contribute at http://dev.joyent.com/

$Id$
=end #(end)

require 'digest/sha1'
require 'ezcrypto' # needs to be here too for via drb

class User < ActiveRecord::Base
  validates_presence_of     :identity_id
  validates_presence_of     :organization_id
  validates_presence_of     :person_id
  validates_presence_of     :username
  validates_presence_of     :password
  validates_format_of       :username, :with => /^[a-z]([_.]?[a-z0-9]+)*$/
  validates_length_of       :username, :maximum => 50
  validates_length_of       :password, :maximum => 50
  validates_uniqueness_of   :username, :scope => 'organization_id'
  validates_uniqueness_of   :person_id
  validates_confirmation_of :password, :on => :create

  belongs_to :identity
  belongs_to :organization
  belongs_to :person
  has_one    :login_token, :dependent => :destroy, :order => 'created_at DESC'
  
  has_many   :user_options,       :dependent => :destroy
  has_many   :subject_of_reports, :dependent => :destroy, :as => :reportable

  has_many   :smart_groups,     :order => 'LOWER(name)', :dependent => :destroy
  belongs_to :documents_folder, :class_name => 'Folder', :foreign_key => 'documents_id' # wack wording, but whatev

  has_many   :taggings, :foreign_key => 'tagger_id', :dependent => :destroy
  has_many   :comments, :dependent => :destroy
  has_many   :permissions_for_items, :class_name => 'Permission', :dependent => :destroy
  has_many   :notifications, :class_name => 'Notification', :foreign_key => 'notifiee_id', :dependent => :destroy, :order => 'notifications.created_at DESC'
  has_many   :current_notifications, :class_name => 'Notification', :foreign_key => 'notifiee_id', :dependent => :destroy, :order => 'notifications.created_at DESC', :conditions => ["acknowledged = ?", false]
  has_many   :sent_notifications, :class_name => 'Notification', :foreign_key => 'notifier_id', :dependent => :destroy, :order => 'notifications.created_at DESC'

  # core item type ownership
  has_many   :mailboxes,       :dependent => :destroy, :order => 'LOWER(mailboxes.full_name)'
  has_many   :calendars,       :dependent => :destroy, :order => 'LOWER(calendars.name)'
  has_one    :contact_list,    :dependent => :destroy
  has_many   :folders,         :dependent => :destroy, :order => 'LOWER(folders.name)'
  has_one    :bookmark_folder, :dependent => :destroy
  has_many   :list_folders,    :dependent => :destroy

  has_many   :messages,        :dependent => :destroy
  has_many   :events,          :dependent => :destroy
  has_many   :people,          :dependent => :destroy
  has_many   :joyent_files,    :dependent => :destroy
  has_many   :bookmarks,       :dependent => :destroy
  has_many   :lists,           :dependent => :destroy

  has_many   :invitations,     :dependent => :destroy
  has_many   :reports,         :dependent => :destroy, :order => 'position'
  has_many   :subscriptions,   :dependent => :destroy
  has_many   :calls,           :dependent => :destroy, :order => 'created_at desc', :foreign_key => "caller_id"
  
  has_many   :guest_paths, :class_name => 'GuestPath', :foreign_key => 'guest_id'
  
  delegate   :tz, :to => :person

  before_create :encrypt_password
  
  cattr_accessor :jajah_system
  @@jajah_system = TestJajahSystem.new
  
  @@aes_salt = JoyentConfig.user_aes_salt
  @@current = nil
  @@valid_languages = ['en', 'es', 'de','it']

  # login/password related

  def self.current=(user)
    @@current  = user
    @@selected = user
  end
  
  def self.current
    @@current
  end

  def self.selected=(user)
    raise "Selected user must be valid" if user.blank? or ! user.is_a?(User)
    @@selected = user
  end
  
  def self.selected
    @@selected
  end

  def authenticate(pass, sha1=false)
    auth = sha1 ? Digest::SHA1.hexdigest(plaintext_password) == pass : password == encrypt(pass)
    self.update_attributes(:recovery_token => '') if auth
    auth
  end
  
  def plaintext_password
    decrypt(password)
  end       
  
  def update_password(new_password, confirm_password)
    return false if new_password.blank?
    return false unless new_password == confirm_password

    self.password = encrypt(new_password)
  end
  
  def remember_login
    self.create_login_token
  end
  
  def generate_login_token
    Digest::SHA1.hexdigest("#{self.id}#{self.organization_id}#{self.plaintext_password}#{Time.now}")
  end
  
  def reset_password!(new_recovery_email = nil)
    token = generate_login_token
    self.update_attributes(:recovery_token => token)
    unless new_recovery_email.blank?
      self.update_attributes(:recovery_email => new_recovery_email)
    end
    
    SystemMailer.deliver_reset_password(self)
  end
  
  # identity

  def switch_to(user_id)
    user = User.current.identity.users.find(user_id)
    LoginToken.current.update_attributes(:user_id => user.id)
    user
  rescue ActiveRecord::RecordNotFound
    RAILS_DEFAULT_LOGGER.info "User '#{User.current.id}' doesn't have permission to switch to user '#{user_id}'"
    raise JoyentExceptions::UserNotConnectedToIdentity
  end
  
  def connect_other_user(other_web_domain, other_username, other_password)
    return false unless (other_domain   = Domain.find_by_web_domain(other_web_domain) and
                         other_user     = other_domain.organization.users.find_by_username(other_username) and
                         other_password == other_user.plaintext_password)

    old_identity = other_user.identity
    other_user.update_attributes!(:identity_id => self.identity_id)
    old_identity.destroy if old_identity.users.length == 0
    true
  end
  
  def disconnect_other_user(user)
    return unless self.identity.users.find_by_id(user.id)
    return unless new_identity = Identity.create
    
    user.update_attributes!(:identity_id => new_identity.id)
    
    # remove from both users'
    Subscription.remove_by_owner(User.current, user)
    Subscription.remove_by_owner(user, User.current)
  end
  
  def identity_other_users
    identity.users.reject{|u| u == self}
  end

  def has_other_identities?
    self.identity_other_users.length > 0
  end
  
  # misc
  
  def full_name
    read_attribute(:full_name) || person.full_name
  end
  
  def other_users
    @other_users ||= self.organization.users.reject{|u| u.guest?} - [self]
  end
  
  def guests
    @guests ||= self.organization.users.find(:all, :conditions => ['guest = ?', true])
  end

  def application_smart_groups(application_name)
    return [] unless smart_group_description = SmartGroupDescription.find_by_application_name(application_name)
    self.smart_groups.find(:all, :conditions => [ "smart_group_description_id = ?", smart_group_description.id ])
  end

  def <=>(right_user)
    person <=> right_user.person
  end

  def get_option(key)
    user_options.detect{|uo| uo.key == key}.value rescue nil
  end

  def set_option(key, value)
    o = user_options.find_by_key(key)
    o ||= UserOption.new(:user_id => self.id, :key => key)
    o.value = value
    o.save
    o
  end
  
  def language
    lang = User.current.get_option('Language')
    @@valid_languages.include?(lang) ? lang : 'en'
  end
  
  # helper for creating reports
  def create_report(report_description_id, reportable_id)
    report_desc = ReportDescription.find(report_description_id)
    reportable  = report_desc.reportable_type.find(reportable_id, :scope => :read)
    report      = reports.create(:report_description => report_desc, :reportable => reportable, :organization => Organization.current)
  end

  # mail related
  
  def inbox
    mailboxes.find(:first, :conditions => ['mailboxes.full_name = ?', 'INBOX'], :include => [:owner], :scope => :read)
  end
  
  def sent
    mailboxes.find(:first, :conditions => ['mailboxes.full_name = ?', 'INBOX.Sent'], :include => [:owner], :scope => :read)
  end

  def drafts
    mailboxes.find(:first, :conditions => ['mailboxes.full_name = ?', 'INBOX.Drafts'], :include => [:owner], :scope => :read)
  end

  def trash
    mailboxes.find(:first, :conditions => ['mailboxes.full_name = ?', 'INBOX.Trash'], :include => [:owner], :scope => :read)
  end

  def system_email
    dom = self.organization.system_domain
    "#{username}@#{dom.email_domain}"
  end
  
  def from_addresses
    return [system_email] if person.email_addresses.empty?
    
    if person.email_addresses.first.preferred?
      person.email_addresses.collect(&:email_address).push system_email
    else
      person.email_addresses.collect(&:email_address).unshift system_email
    end
  end

  # files
  
  def root_path
    File.join(organization.users_path, username)
  end
  
  def services_root_path
    File.join(self.strongspace_root_path, Service::SERVICE_DIRECTORY_NAME)
  end
  
  def strongspace_root_path
    File.join(self.root_path, 'strongspace')
  end

  def services
    MockFS.file_utils.mkdir_p self.services_root_path unless MockFS.file.exist?(self.services_root_path)

    MockFS.dir.entries(self.services_root_path).collect do |directory|
      Service.new(File.join(self.services_root_path, directory), self) unless directory[0,1] == '.'
    end.compact.select{|service| service.root_folder}.sort
  end
  
  # notifications

  # a user can be notified of the same item more than once
  def notify_of(item, notifier, message='')
    notifications.create(:item => item, :notifier => notifier, :organization => organization, :message => message)
  end

  def has_been_notified_of?(item)
    ! find_notification_for(item).nil?
  end

  def active_notifications_for(item)
    notifications.find(:all, :conditions => ['item_type = ? AND item_id = ?', item.class.to_s, item.id]).reject{|n| n.acknowledged}
  end

  # finds the most recent notification
  def find_notification_for(item)
    notifications.find(:first, :conditions => ['item_type = ? AND item_id = ?', item.class.to_s, item.id])
  end

  def notifications_count(item_type, include_all = false)
    if item_type && include_all
      notifications.count(:conditions => ['item_type = ?', item_type])
    elsif item_type
      notifications.count(:conditions => ['item_type = ? and acknowledged = ?', item_type, false])
    elsif include_all
      notifications.count
    else
      notifications.count(:conditions => ['acknowledged = ?', false])
    end
  end

  # tags

  def tags
    Tag.find(:all, :include => :taggings, :conditions => ['taggings.tagger_id = ?', self.id], :order => 'LOWER(tags.name)') # TODO: is uniq needed?
  end

  def tag_item(item, tag_name)
    Tag.transaction do 
      tag = organization.tags.find_or_create_by_name(tag_name)
      t = taggings.create(:tag => tag, :taggable => item)
      item.save
      t        
    end
  end

  # TODO: This method does not seem correct.  I believe our 'design' is not supposed to allow
  #       others to remove our tags on an item, but this method seems to let that happen (the UI
  #       is likely the thing that prevents it)
  def untag_item(item, tag_name) 
    return unless tag = organization.tags.find_by_name(tag_name)
    return unless tagging = item.taggings.find_by_tag_id_and_taggable_id(tag.id, item.id)
    Tag.transaction do
      item.save
      tagging.destroy                                                               
    end
  end

  # calendar
  
  def calendar_busy?(event)
    return false unless event.is_a?(Event)
    return false if event.blank?

    self.busy_during?(event)
  end

  def pending_invitations
    self.invitations.find(:all, :conditions=>["pending = ?", true])
  end

  def today
    self.person.tz.now.to_date
  end
  
  def now
    self.person.tz.now
  end

  CANDIDATE_EVENTS_SQL = "select events.* from events where id in (select event_id from invitations where user_id=? and accepted=true) and recurrence_description_id is not null and ( ((recur_end_time > ? AND start_time < ?)) or (start_time < ? and recur_end_time is null) )"
  COUNT_NON_REPEATING_EVENTS_SQL = "select count(*) from events where id in (select event_id from invitations where user_id=? and accepted=true) and (end_time > ? AND start_time < ?) and all_day = false"
  def busy_during?(event)
    if 0 != User.count_by_sql([COUNT_NON_REPEATING_EVENTS_SQL, self.id, event.start_time, event.end_time])
      return true
    else
      # all the repeating events which this user is attending which could possibly match
      f = event.start_time_in_user_tz
      t = event.end_time_in_user_tz
      candidate_events = Event.find_by_sql([CANDIDATE_EVENTS_SQL, self.id, event.start_time,event.end_time,event.start_time])
      candidate_events.find do |event_test|         
        event_test.occurrences_between(f,t).size > 0
      end
    end
  end

  # comments
  
  def comment_on_item(item, body)
    comments.create(:commentable => item, :body => body)
  end

  # app group accessors

  def mail_root_mailboxes
    return @__mail_root_mailboxes if @__mail_root_mailboxes

    inbox = mailboxes.find_by_full_name('INBOX', :include => {:children => [:permissions]})
    @__mail_root_mailboxes = if inbox
      inbox.children.reject{|mb| mb.special?}.select{|m| User.current.can_view?(m)}
    else
      []
    end
  end

  def calendar_root_calendars
    calendars.select{|c| c.parent_id == nil}.select{|c| User.current.can_view?(c)}
  end

  def people_contact_list
    User.current.can_view?(contact_list) ? contact_list : nil
  end

  def files_documents_folder
    folder = folders.find(:first, :conditions => ["folders.name = 'Documents' AND parent_id IS NULL"], :order => 'folders.id')
    User.current.can_view?(folder) ? folder : nil
  end
  
  def files_root_folders
    root_folders = folders.select{|f| f.parent_id == nil}
    root_folders.reject!{|f| f == files_documents_folder}
    root_folders.select{|f| User.current.can_view?(f)}
  end
  
  def bookmarks_bookmark_folder
    User.current.can_view?(bookmark_folder) ? bookmark_folder : nil
  end

  def lists_list_folder
    list_folder = list_folders.find(:first, :conditions => ["list_folders.name = 'Lists' AND list_folders.parent_id IS NULL"])
    User.current.can_view?(list_folder) ? list_folder : nil
  end

  def lists_root_folders
    root_groups = list_folders.select{|lf| lf.parent_id == self.lists_list_folder.id}
    root_groups.select{|lf| User.current.can_view?(lf)}
  end

  def browser_root_groups_for(application_name)
    case application_name
    when 'connect'   then []
    when 'mail'      then [inbox, sent, drafts, trash] + mail_root_mailboxes
    when 'calendar'  then calendar_root_calendars
    when 'people'    then [people_contact_list]
    when 'files'     then [files_documents_folder] + files_root_folders
    when 'bookmarks' then [bookmarks_bookmark_folder]
    when 'lists'     then [lists_list_folder] + lists_root_folders
    else
      raise 'unknown application_name'
    end
  end
  
  # subscriptions
  
  def subscriptions_to_group_type(group_type)
    group_type = group_type.to_s.gsub(/\s/, '')
    self.subscriptions.find_by_type(group_type) || []
  end
  
  def subscribed_to?(group, type=nil, id=nil)
    if type
      type = type.to_s.gsub(/\s/, '')
      ! self.subscriptions.find(:first, :conditions => {:subscribable_type => type, :subscribable_id => id}).blank?
    else
      ! self.subscriptions.find(:first, :conditions => {:subscribable_type => group.class.to_s, :subscribable_id => group.id}).blank?
    end
  end
  
  def subscribed_group(group)
    self.subscriptions.find(:first, :conditions => {:subscribable_type => group.class.to_s, :subscribable_id => group.id}) || nil
  end
  
  # security

  def owns?(item)
    !! (item && item.respond_to?(:owner) && (self == item.owner))
  end

  def can_view?(item)
    return false unless item
    item.permissions.empty? || item.permissions.map(&:user_id).include?(id)
  end

  def can_edit?(item)
    return false unless item 
    return false unless can_view?(item)

    if item.is_a?(Person) and item.user
      self.admin? or item == self.person
    else
      owns?(item)
    end
  end

  def can_copy?(item)
    return false unless item
    can_view?(item)
  end

  def can_email?(item)
    return false unless item
    can_copy?(item)
  end

  def can_move?(item)
    return false unless item
    case item.class.name
      when 'Event', 'StubEvent'
        invite = item.invitation_for(self)
        !! (invite && invite.calendar)
      when 'Person', 'Bookmark'
        false # categorized by type
      else
        owns?(item)
    end
  end                     
  
  def can_delete?(item)
    return false unless item
    item = item.person if item.kind_of?(User) # used when deleting users

    if item.kind_of?(Person) and item.user
      return false if ! self.admin? # must be admin to delete users
      return false if item == self.person # no suicide
      true
    else  
      owns?(item)
    end
  end

  # does not indicate if the item can actually be deleted
  def must_confirm_delete?(item)
    return false unless item
    return true if item.kind_of?(Person) and (item.admin? or item.user?)
    false
  end

  # can the user create items on this group?
  def can_create_on?(group)
    return false unless group
    owns?(group)  
  end
  
  # can the user create children groups on this group?
  def can_create_child_on?(group)
    return false unless group

    case group.class.name
    when 'Mailbox'
      if group.special?
        false
      else
        owns?(group)
      end
    when 'Calendar'
      owns?(group)
    when 'ContactList', 'BookmarkFolder'
      false
    when 'Folder'
      if group == User.current.files_documents_folder
        false
      else
        owns?(group)
      end
    else
      false # unknown
    end
  end

  def can_copy_from?(group)
    return false if guest? # XXX THIS MAY CHANGE, IT'S A TEMP QUICK FIX
    return false unless group
    true  
  end

  def can_email_from?(group)
    return false unless group
    can_copy_from?(group)
  end
  
  def can_move_from?(group)
    return false unless group
    owns?(group)  
  end
    
  def can_delete_from?(group)
    return false unless group
    owns?(group)  
  end
  
  def authorized_keys_path
    File.join(strongspace_root_path, '.ssh', 'authorized_keys')  
  end
  
  def add_ssh_public_key(public_key)
    keys = read_authorized_keys + [public_key.strip]
    write_authorized_keys(keys)
    self.save
  end
  
  def remove_ssh_public_key(public_key)
    keys = read_authorized_keys - [public_key.strip]
    write_authorized_keys(keys)
    self.save
  end
  
  def strongspace_folder
    StrongspaceFolder.find_root(self)
  end
  
  def guest_folders
    guest_paths.inject([]) do |arr, p|
      begin
        arr << StrongspaceFolder.from_guest_path(p)
      rescue StrongspaceFolder::FolderNotFound
        # If the folder isn't found, it was removed via the web app or sftp,
        # so we need to eliminate the GuestPath object.
        p.destroy
      end
      arr
    end
  end
  
  def uid
    RAILS_ENV == 'production' ? id + 5000 : MockFS.file.stat(strongspace_root_path).uid
  end

  def update_file_permissions
    MockFS.file_utils.chmod_R(0751, self.root_path)
    Chown.chown_R('root', self.organization.gid.to_s, self.root_path)
  
    MockFS.dir.entries("#{self.root_path}").each do |entry|
      next if ['.', '..'].include?(entry)
      MockFS.file_utils.chmod_R(0700, "#{self.root_path}/#{entry}")
    end

    MockFS.file_utils.chmod_R(0770, self.strongspace_root_path)
    MockFS.file.chmod(0700, self.services_root_path)

    Chown.chown_R(self.system_email, self.organization.gid.to_s, self.strongspace_root_path)
  end
  
  def jajah_password
    decrypt(read_attribute(:jajah_password))
  end
  
  def jajah_password=(new_password)
    write_attribute(:jajah_password, encrypt(new_password))
  end
  
  private

    def encrypt(password)
      return password unless !password.blank?
      encrypted = EzCrypto::Key.encrypt_with_password(username.downcase, @@aes_salt, password)
      encrypted = Base64.encode64(encrypted)
    end
    
    def decrypt(password)
      return password unless !password.blank?
      EzCrypto::Key.decrypt_with_password(username.downcase, @@aes_salt, Base64.decode64(password))
    end
  
    def encrypt_password
      write_attribute(:password, encrypt(password))
    end 
    
    def read_authorized_keys
      return [] unless MockFS.file.exist?(authorized_keys_path)

      File.readlines(authorized_keys_path).collect{|key| key.strip}.reject{|key| key == ''}
    end

    def write_authorized_keys(keys)
      keys = keys || []
      
      RunAs.run_as(self.uid, self.organization.gid) do
        umask = File.umask 0077
        MockFS.file_utils.mkdir_p(File.dirname(authorized_keys_path))
        
        File.umask 0177
        MockFS.file.open(authorized_keys_path, 'w') do |file|
          keys.collect{|key| key.strip}.uniq.compact.each{|key| file.write(key + "\n")}
        end
                
        File.umask umask
      end
    end
end
