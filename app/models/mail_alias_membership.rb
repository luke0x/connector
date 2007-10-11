=begin #(fold)
++
Copyright 2004-2007 Joyent Inc.

Redistribution and/or modification of this code is 
governed by the GPLv2.

Report issues and contribute at http://dev.joyent.com/

$Id$
--
=end #(end)

class MailAliasMembership < ActiveRecord::Base
  belongs_to :mail_alias
  belongs_to :user

  after_create :create_smart_group
  before_destroy :destroy_smart_group
  
  protected
  
    def create_smart_group
      name = _("%{name} Alias") % {:name => mail_alias.name}
      smart_group_description = SmartGroupDescription.find_by_application_name('Mail')
      return if User.current.smart_groups.find(:first, :conditions => ['name = ? AND smart_group_description_id = ? AND special = true', name, smart_group_description.id])
      
      smart_group = User.current.new_smart_group('Mail', name)
      smart_group.make_special!
      smart_group.add_condition('To', "#{mail_alias.name}@")
      smart_group.add_condition('Owner Username', User.current.username)
    end
  
    def destroy_smart_group
      name = _("%{name} Alias") % {:name => mail_alias.name}
      smart_group_description = SmartGroupDescription.find_by_application_name('Mail')

      smart_group = User.current.smart_groups.find(:first, :conditions => ['name = ? AND smart_group_description_id = ? AND special = true', name, smart_group_description.id])
      smart_group.destroy if smart_group and smart_group.smart_group_attributes.length == 2
    end
end