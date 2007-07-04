=begin #(fold)
Copyright 2004-2007 Joyent Inc.

Redistribution and/or modification of this code is governed
by either the GPLv2 or Joyent Commercial Software licenses.

Report issues and contribute at http://dev.joyent.com/

$Id$
=end #(end)

class UserObserver < ActiveRecord::Observer
  cattr_accessor :new_user_email
  @@new_user_email = true
  
  def after_create(user)
    if user.guest?
      if UserObserver.new_user_email
        user.update_attributes!(:recovery_token => user.generate_login_token)
        SystemMailer.deliver_guest_welcome_email(user)
      end
    else
      user.documents_folder = user.folders.create(:name => 'Documents', :organization_id => user.organization_id)
      user.save
      user.calendars.create(:name => user.full_name, :organization_id => user.organization_id)
      user.create_contact_list(:organization_id => user.organization_id)
      user.create_bookmark_folder(:organization_id => user.organization_id)
      user.list_folders.create(:name => 'Lists', :organization_id => user.organization_id)

      user.organization.domains.each do |dom|
        a = "#{user.username}@#{dom.email_domain}"
        unless user.person.email_addresses.find_by_email_address(a)
          user.person.email_addresses.create({:email_address=>a, :email_type=>"Work", :preferred=>dom.primary?})
        end
      end

      Person.ldap_system.write_user(user) # do this before the email gets sent 
      if UserObserver.new_user_email
        SystemMailer.deliver_welcome_email(user)
      end

      MockFS.file_utils.mkdir_p user.services_root_path

      # HACK ALERT: need to find a better place for this, could be refactored into a subclass of Service::Base
      MockFS.file_utils.mkdir_p(File.join(user.services_root_path, 'lightning'))
      
      user.update_file_permissions
    end
  end

  def after_save(user)
    Person.ldap_system.write_user(user)
    Person.ldap_system.update_organization(user.organization)
  end
  
  def after_destroy(user)
    Calendar.find_all_by_user_id(user.id).each(&:destroy)
    Person.ldap_system.remove_user(user)
    Person.ldap_system.update_organization(user.organization)
    MockFS.file_utils.rm_rf user.root_path
    JoyentMaildir::Base.remove_user(user)
  end                                                
end