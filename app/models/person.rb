=begin #(fold)
++
Copyright 2004-2007 Joyent Inc.

Redistribution and/or modification of this code is 
governed by the GPLv2.

Report issues and contribute at http://dev.joyent.com/

$Id$
--
=end #(end)

class Person < ActiveRecord::Base
  include JoyentItem

  before_save   :set_sort_caches
  after_save    :save_icon    
  after_destroy :remove_icon
  
  belongs_to :contact_list
  has_one    :user
  has_many   :addresses,       :dependent => :destroy, :order=>"preferred desc"
  has_many   :email_addresses, :dependent => :destroy, :order=>"preferred desc"
  has_many   :im_addresses,    :dependent => :destroy, :order=>"preferred desc"
  has_many   :phone_numbers,   :dependent => :destroy, :order=>"preferred desc"
  has_many   :special_dates,   :dependent => :destroy, :order=>"preferred desc"
  has_many   :websites,        :dependent => :destroy, :order=>"preferred desc"
  has_many   :callings,        :dependent => :nullify, :foreign_key => "callee_id"

  composed_of :tz, :class_name => 'TZInfo::Timezone', :mapping => %w(time_zone time_zone)

  @@colors = [ "FA9D0C", "7922FA", "CB8737", "4FA84B", "78594C", "FA6310", "21B7FA", "BC472C", "A16D30", "784753",
               "FA1713", "64D972", "BB345C", "8E3F4D", "6B4278", "FA1B5B", "B5D95E", "BB31AB", "79668E", "344278",
               "FA1599", "D9CF62", "6A30BB", "487178", "375F62", "E22DFA", "5164BB", "48A2BB", "49BB98", "56303C" ]
  
  @@default_icon = "#{RAILS_ROOT}/public/images/icons/unavailableUserIcon.png"

  cattr_accessor :ldap_system
  @@ldap_system = TestLdapSystem.new
  
  def self.search_fields
    [
      'users.username',
      'users.full_name',
      'people.company_name',
      'people.first_name',
      'people.middle_name',
      'people.last_name',
      'people.title',
      'people.notes',
      'people.person_type',
      'people.primary_email_cache',
      'people.primary_phone_cache'
    ]
  end
  
  def Person.from_vcards(vcard_content)
    VcardConverter.create_people_from_vcards(vcard_content)
  end

  def full_name
    [name_prefix, first_name, middle_name, last_name, name_suffix].reject(&:blank?) * ' '
  end
  alias_method :name,  :full_name

  # returns the hex value of the user's color
  def color
    @@colors[self.id % @@colors.length]
  end
  
  def write_to_ldap!
    JoyentJob::Job.new(self.class, self.id, :real_write_to_ldap!).submit
  end
  
  def real_write_to_ldap!
    @@ldap_system.write_person(self)
  end
  
  def remove_from_ldap!
    @@ldap_system.remove_person(self)
  end
  
  def admin?
    (! user.blank?) and user.admin?
  end
  
  # admin or regular user
  def user?
    (! user.blank?) and (! user.guest?)
  end
  
  def guest?
    (! user.blank?) and user.guest?
  end
  
  def contact?
    user.blank?
  end

  def account_type
    if    admin?   then 'admin'
    elsif user?    then 'user'
    elsif guest?   then 'guest'
    elsif contact? then 'contact'
    else
      'unknown'
    end
  end
  
  def exportable?
    admin? || user? || permissions.empty?
  end
   
  def has_icon?
    saved_icon_file || @icon_details
  end
  
  def icon
    if has_icon?
      if saved_icon_file
        MockFS.file.open(saved_icon_file) {|f| f.read}
      else
        @icon_details[0]
      end
    else
      MockFS.file.open(@@default_icon) {|f| f.read}
    end
  end
  
  def icon_type
    return unless self.has_icon?

    if @icon_details
      @icon_details[1]
    else
      File.extname(saved_icon_file)[1..-1]
    end
  end
 
  def add_icon(content, type)
    return if content.blank? || type.blank?

    if new_record?
      @icon_details = [content, type]
    else
      self.remove_icon 
      icon_file = File.join(self.organization.icons_path, "#{self.id}.#{type.downcase}")
      MockFS.file.open(icon_file, 'w'){|file| file.write(content)}
    end
  end

  def remove_icon
    MockFS.file.delete(saved_icon_file) if saved_icon_file
    @icon_details = nil
  end
        
  def copy_to(contact_list)   
    new_person       = contact_list.people.create(self.attributes)
    new_person.owner = contact_list.owner
              
    # Clone the associated objects   
    addresses.each       {|address| new_person.addresses.create(address.attributes)     }
    phone_numbers.each   {|phone|   new_person.phone_numbers.create(phone.attributes)   }
    special_dates.each   {|date|    new_person.special_dates.create(date.attributes)    }
    websites.each        {|website| new_person.websites.create(website.attributes)      }
    email_addresses.each {|email|   new_person.email_addresses.create(email.attributes) }
    im_addresses.each    {|im|      new_person.im_addresses.create(im.attributes)       }
    
    permissions.each     {|perm|    new_person.permissions.create(perm.attributes)      }    
    
    if has_icon?                          
      new_person.add_icon(icon, icon_type)
    end                 
    
    new_person.save                    
    
    new_person
  end
  
  # person: the new person params
  def update_user_from_params(person_params)
    # nothing to be done if a contact
    return if person_params.has_key?('type') and person_params['type'] == 'contact'

    # creating
    if person_params.has_key?('type') and User.current.admin?
      if person_params['type'] == 'user'
        return if person_params['username'].blank?
        return if person_params['password'].blank?
        return unless person_params['password'] == person_params['password_confirmation']

        self.user = User.current.organization.users.create(:identity  => Identity.create,
                                                      :username  => person_params['username'],
                                                      :password  => person_params['password'],
                                                      :recovery_email => person_params['recovery_email'],
                                                      :person_id => self.id,
                                                      :admin     => (person_params['admin'] and person_params['admin'] == 'on') ? true : false)

        self.owner = self.user # ensure the user is their own owner
      elsif person_params['type'] == 'guest'
        return if person_params['username'].blank?

        self.user = User.current.organization.users.create(:identity  => Identity.create,
                                                      :username  => person_params['username'],
                                                      :password  => Digest::SHA1.hexdigest("#{JoyentConfig.user_new_password_salt}#{Time.now}")[0..20],
                                                      :recovery_email => person_params['recovery_email'],
                                                      :person_id => self.id,
                                                      :admin     => false,
                                                      :guest     => true,
                                                      :guest_rw  => (person_params['guest_readwrite'] and person_params['guest_readwrite'] == 'on') ? true : false)
        self.owner = self.user # ensure the user is their own owner
      end

    # updating admin or user
    elsif self.admin? or self.user?
      # maybe update the user's password
      # first make sure either an admin or the person's user is changing the password
      if User.current.admin? or User.current == self.user
        # next make sure password info is valid
        if ! person_params['password'].blank? and person_params['password'] == person_params['password_confirmation']
          self.user.update_password(person_params['password'], person_params['password_confirmation'])
        end
        self.user.update_attributes(:recovery_email => person_params['recovery_email'])
      end

      # only admins can give admin status, and can't revoke it from themself
      if User.current.admin? and User.current != self.user
        u = self.user
        u.admin = (person_params['admin'] and person_params['admin'] == 'on') ? true : false
        u.save
      end

      self.owner = self.user # ensure the user is their own owner

    # updating guest
    elsif self.guest?
      if User.current.admin? or User.current == self.user
        rw = (person_params['guest_readwrite'] and person_params['guest_readwrite'] == 'on') ? true : false
        self.user.update_attributes(:recovery_email => person_params['recovery_email'], :guest_rw => rw)
      end
      self.owner = self.user # ensure the user is their own owner
    end
    
    # update other user settings
    if self.user and ! self.user.new_record?
      self.user.set_option('Language', person_params['language']) if person_params.has_key?('language')

      self.phone_numbers.select(&:use_notifier?).each{|x|   x.update_attributes(:use_notifier => false, :confirmed => false, :provider => '')}
      self.email_addresses.select(&:use_notifier?).each{|x| x.update_attributes(:use_notifier => false)}
      self.im_addresses.select(&:use_notifier?).each{|x|    x.update_attributes(:use_notifier => false)}
      if person_params.has_key?('notifier_sms') and x = self.phone_numbers.find_by_phone_number(person_params['notifier_sms'])
        x.update_attributes(:use_notifier => true, :confirmed => true)
        x.update_attributes(:provider => person_params['notifier_sms_provider']) if person_params.has_key?('notifier_sms_provider')
      end
      if person_params.has_key?('notifier_email') and x = self.email_addresses.find_by_email_address(person_params['notifier_email'])
        x.update_attributes(:use_notifier => true)
      end
      if person_params.has_key?('notifier_im') and x = self.im_addresses.find_by_im_address(person_params['notifier_im'])
        x.update_attributes(:use_notifier => true) if x.im_type == 'Jabber'
      end
    end

    self.save
  end
  
  def to_vcard    
    VcardConverter.create_vcards_from_people(self)
  end

  def save_from_params(person_params)
    valid_params = ['first_name', 'middle_name', 'last_name', 'company_name', 'title', 'time_zone', 'notes']
    collection_params = ['phone_numbers', 'email_addresses', 'addresses', 'im_addresses', 'websites', 'special_dates']

    # un-munge guest params
    person_params['language']       = person_params['guest_language']       if person_params['language'].blank?
    person_params['recovery_email'] = person_params['guest_recovery_email'] if person_params['recovery_email'].blank?
    person_params['time_zone']      = person_params['guest_time_zone']      if person_params['time_zone'].blank?
    person_params['username']       = person_params['guest_username']       if person_params['username'].blank?

    # update person
    self.organization = User.current.organization
    self.owner = User.current
    self.update_attributes(person_params.limit_keys_to(valid_params))
    self.reload

    # un-munge the collections with indexes
    person_params['phone_numbers']   = person_params['phone_numbers'].collect{|k,v|   PhoneNumber.new(v)}  || [] rescue []
    person_params['email_addresses'] = person_params['email_addresses'].collect{|k,v| EmailAddress.new(v)} || [] rescue []
    person_params['addresses']       = person_params['addresses'].collect{|k,v|       Address.new(v)}      || [] rescue []
    person_params['im_addresses']    = person_params['im_addresses'].collect{|k,v|    ImAddress.new(v)}    || [] rescue []
    person_params['websites']        = person_params['websites'].collect{|k,v|        Website.new(v)}      || [] rescue []
    person_params['special_dates']   = person_params['special_dates'].collect do |k, special_date|
      special_date['special_date'] = Date.parse("#{special_date.delete(:year)}-#{special_date.delete(:month)}-#{special_date.delete(:day)}") rescue nil
      SpecialDate.new(special_date)
    end || [] rescue []
    collection_params.each do |cp|
      person_params[cp].each do |cpp|
        cpp['person_id'] = self.id.to_i
      end
    end
    
    # This is a pretty intensive line...it does a lot of deletes and adds for all of the associations
    self.update_attributes(person_params.limit_keys_to(collection_params))
    self.reload

    self.update_user_from_params(person_params)

    # maintain contact_list link - TODO: how could this be done better?
    self.contact_list = (self.user) ? nil : User.current.contact_list
    self.save
    
    unless person_params[:icon_file].blank?
      ext = File.extname(person_params[:icon_file].original_filename)
      ext = ext.length > 1 ? ext[1..-1] : 'jpg'
      self.add_icon(person_params[:icon_file].read, ext)
    end
    
    self
  end

  def update_guest_from_params(params)
    return false unless user and user.guest?

    self.update_attributes(:time_zone => params[:time_zone])

    u = self.user
    u.update_password(params[:password], params[:password_confirmation])
    u.recovery_email = params[:recovery_email]
    u.save

    o = self.user.set_option('Language', params[:language])

    self.errors.blank? and u.errors.blank? and o.errors.blank?
  end

  def class_humanize
    if admin? or user?
      'User'
    elsif guest?
      'Guest'
    else
      'Contact'
    end
  end
  
  def <=>(right_person)
    left = "#{last_name} #{first_name} #{middle_name}"
    right = "#{right_person.last_name} #{right_person.first_name} #{right_person.middle_name}"
    left <=> right
  end

  # HAX helper for tzinfo_timezone_select
  def guest_time_zone
    time_zone
  end
  
  # find the first email marked as preferred to use as the primary email
  def primary_email
    email_addresses.find(:first, :conditions => {:preferred => true}) || email_addresses.first
  end
  
  # find the first phone number marked as preferred to use as the primary number
  def primary_phone
    phone_numbers.find(:first, :conditions => {:preferred => true}) || phone_numbers.first
  end                
  
  def to_utc(time)
    return unless time
    
    begin
      tz.local_to_utc(time)
    rescue TZInfo::AmbiguousTime 
      tz.local_to_utc(time, true) 
    rescue TZInfo::PeriodNotFound
      tz.local_to_utc(time + 1.hour)
    end
  end
  
  def to_local(time)
    return unless time
    
    tz.utc_to_local(time)
  end
  
  private

    def save_icon
      self.add_icon(@icon_details[0], @icon_details[1]) if @icon_details
    end

    def saved_icon_file
      MockFS.dir.glob(File.join(self.organization.icons_path, "#{self.id}.*")).first if self.organization and self.id
    end
  
    def set_sort_caches
      self.person_type = if self.admin?
        '0_Admin'
      elsif self.user?
        '1_User'
      elsif self.guest?
        '1_User_Guest'
      else
        '2_Contact'
      end
      self.primary_email_cache = primary_email.blank? ? '' : primary_email.email_address
      self.primary_phone_cache = primary_phone.blank? ? '' : primary_phone.phone_number
    end
end
