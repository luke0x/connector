=begin #(fold)
++
Copyright 2004-2007 Joyent Inc.

Redistribution and/or modification of this code is 
governed by the GPLv2.

Report issues and contribute at http://dev.joyent.com/

$Id$
--
=end #(end)

class Organization < ActiveRecord::Base
  validates_presence_of :name
  validates_presence_of :affiliate_id
  
  belongs_to :affiliate

  has_many :users,         :dependent => :destroy, :order => 'LOWER(full_name) ASC'
  has_many :tags,          :dependent => :destroy
  has_many :notifications, :dependent => :destroy
  has_one  :quota,         :dependent => :destroy
  has_many :domains,       :dependent => :destroy
  has_many :smart_groups
  has_many :reports
  has_many :mail_aliases, :dependent => :destroy, :order => 'LOWER(name)'

  has_many :mailboxes
  has_many :calendars
  has_many :contact_lists
  has_many :folders
  has_many :bookmark_folders
  has_many :list_folders

  has_many :messages
  has_many :events
  has_many :people
  has_many :joyent_files
  has_many :bookmarks
  has_many :lists

  before_destroy {|org| !org.active}   
 
  cattr_accessor :ssh_public_key
  @@ssh_public_key = JoyentConfig.organization_ssh_public_key
  
  cattr_accessor :storage_root
  @@storage_root = File.join(RAILS_ROOT, 'tmp', RAILS_ENV, 'storage_root')
  
  def partner?
    affiliate.name != 'joyent'
  end
  
  def activate!
    self.active = true
    self.save!
  end
  
  def deactivate!
    self.active = false
    self.save!
  end

  # mycompany.joyent.net, where 'joyent.net' is the suffix set by convention by the customer application
  def system_domain
    @system_domain ||= self.domains.find(:first, :conditions=>["system_domain = ?", true])
  end
  
  # a domain like mycompany.com, marked primary in the customer application
  def primary_domain
    @primary_domain ||= self.domains.find_by_primary(true)
  end
  
  def search(needle)
    SearchSystem.search(needle)
  end
  
  def disk_usage_in_bytes
    disk_usage * 1.megabyte  
  end
  
  def total_disk_usage
    messages = Message.sum(:size_in_bytes, :conditions => ['organization_id = ?', id]).to_i
    disk_usage_in_bytes + messages
  end
  
  def root_path
    File.join(Organization.storage_root, self.id.to_s)
  end
  
  def icons_path
    File.join(self.root_path, 'icons')    
  end
  
  def users_path
    File.join(self.root_path, 'users')    
  end

  def users_and_admins
    users.reject{|u| u.guest?}
  end
  
  def guests
    users.select{|u| u.guest?}
  end
  
  def can_add_user?
    users.size() < quota.users
  end    
  
  def find_contact_with_email(email_address)
    self.people.find(:first, :include => :email_addresses, :conditions => ['lower(email_addresses.email_address) = ?', email_address.downcase])
  end  
  
  def gid
    RAILS_ENV == 'production' ? id + 5000 : MockFS.file.stat(root_path).gid
  end
    
  # Setup methods
  def self.setup(name, system_domain, username, password, affiliate_name, first_name, last_name, recovery_email, users, megabytes, custom_domains)
    affiliate = Affiliate.find_by_name(affiliate_name) || Affiliate.find(1)
    o = Organization.create(:name=>name, :affiliate_id => affiliate.id)  
    q = o.create_quota(:users=>users, :megabytes=>megabytes, :custom_domains=>custom_domains)
    d = o.domains.create(:system_domain=>true, :primary=>true, :email_domain=>system_domain, :web_domain=>system_domain)  
    o.sync_to_ldap    
    # SearchObserver.enabled = false

    p              = Person.new
    p.organization = o
    p.first_name   = first_name
    p.last_name    = last_name  
    # PDI: I am not sure of the repercussions if we don't set a timezone, so lets set one 
    p.time_zone    = 'America/Los_Angeles'
    p.save(false)
    # SearchObserver.enabled = true
    UserObserver.new_user_email = false
    
    u                = User.new
    u.organization   = o
    u.identity       = Identity.create
    u.username       = username
    u.password       = password
    u.recovery_email = recovery_email
    u.admin          = true   
    u.person         = p
    u.save
    p.owner          = u
    p.save
    p.email_addresses.create(:email_type => 'Work', :email_address => recovery_email, :preferred => true) if recovery_email
    
    UserObserver.new_user_email = true
    
    o.update_file_permissions
    
    return o
  ensure
    # SearchObserver.enabled = true    
  end
  
  def update_file_permissions
    MockFS.file_utils.chmod_R(0750, self.root_path)
    Chown.chown_R('root', self.gid.to_s, self.root_path)
    
    self.users(true).each do |user|
      user.update_file_permissions
    end
  end
  
  def sync_to_ldap
    Person.ldap_system.update_organization(self)
  end   
end
