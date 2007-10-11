=begin #(fold)
++
Copyright 2004-2007 Joyent Inc.

Redistribution and/or modification of this code is 
governed by the GPLv2.

Report issues and contribute at http://dev.joyent.com/

$Id$
--
=end #(end)

class Mailbox < ActiveRecord::Base 
  include JoyentGroup
  
  validates_presence_of     :full_name
  validates_numericality_of :uid_validity, :only_integer => true
  validates_numericality_of :uid_next,     :only_integer => true
  
  has_many :messages, :dependent => :destroy
  
  acts_as_tree :order => 'mailboxes.full_name'
  
  def self.list(user)
		JoyentMaildir::Base.connection.mailbox_list(user.id)
		user_inbox = user.mailboxes.find_by_full_name 'INBOX'
		user.mailboxes.find(:all, :conditions => ["user_id = ? AND parent_id = ? AND full_name NOT IN(?)",
		                                          user.id, user_inbox.id, JoyentMaildir::MailboxSync.specials])
  end
  
  def self.empty_spam(user)
    JoyentMaildir::Base.connection.mailbox_empty_spam(user.id)
    user.spam.messages.each(&:destroy)
  end
  
  def self.empty_trash(user)
		JoyentMaildir::Base.connection.mailbox_empty_trash(user.id)
		user.trash.messages.each(&:destroy)
	end

  def special?
    JoyentMaildir::MailboxSync.specials.include?(self.full_name)
  end
	
  def sync
		JoyentMaildir::Base.connection.mailbox_sync self.id
  rescue DRb::DRbConnError
  end
  
  def count
		JoyentMaildir::Base.connection.mailbox_count self.id
  end
  
  def name
    full_name.split('.').last
  end
  
  def relative_name
    full_name.gsub(/^INBOX\./, '')
  end
  
  def parent_name
    full_name.match(/(.+)\..+$/)[1] rescue nil
  end
      
  def level
    full_name.count('.')
  end
  
  def create_child(child_name)
    return unless User.current.can_create_child_on?(self)
    return if child_name.include?('.')

    new_full_name = [full_name, child_name] * '.'
    # {:uidvalidity => ts, :uidnext => 1}
    
    status = JoyentMaildir::Base.connection.mailbox_create_child(owner.id, new_full_name)
		self.class.create(:full_name		=> new_full_name, 
											:parent				=> self,
											:uid_validity => status[:uidvalidity],
											:uid_next			=> status[:uidnext],
											:owner				=> owner,
											:organization => organization)
  end

	# Used for setting the last part of "full_name", do not use this if you're
	# trying to set the full_name!
	def rename!(name)
    return if name.include?('.')
		parts = full_name.split('.')
		part_to_rename = parts.size - 1
		
		parts[-1] = name
		new_name = parts * '.'
		status = JoyentMaildir::Base.connection.mailbox_rename(self.id, new_name)
		update_attributes :full_name		=> new_name,
											:uid_validity => status[:uidvalidity],
											:uid_next			=> status[:uidnext]
											
		rename_children(children, part_to_rename, name)
	end
	
	def delete!
		return if full_name == 'INBOX'

		JoyentMaildir::Base.connection.mailbox_delete self.id
		delete_children(children)
		destroy
	end
	
  # is this mailbox a descendent of me?
  def descendent?(mailbox)
    return false if mailbox.blank?
    return false if children.blank?
    return true if children.include?(mailbox)
    children.each do |child|
      return true if child.descendent?(mailbox)
    end
    false
  end

	# TODO tests
	def reparent!(new_parent)
		new_parent ||= owner.inbox # 'top level' comes through as nil
		return if new_parent == self
		return if descendent?(new_parent)
		new_name = "#{new_parent.full_name}.#{name}"
		status = JoyentMaildir::Base.connection.mailbox_rename(self.id, new_name)
		update_attributes :full_name		=> new_name,
											:uid_validity => status[:uidvalidity],
											:uid_next			=> status[:uidnext],
											:parent				=> new_parent

    children.each do |child|
      child.reparent!(self)
    end
	end

  # total PDI koz
  def real_cascade_permissions
    users = permissions.collect(&:user)
    if full_name != 'INBOX'
      children.each {|c| c.restrict_to!(users)}
    end
    messages.each {|m| m.restrict_to!(users)}
  end
  
  def cascade_permissions
    JoyentJob::Job.new(Mailbox, self.id, :real_cascade_permissions).submit
  end

  protected

    def delete_children(mailboxes)
  		mailboxes.each do |mb|
  		  mb.delete!
  		end
    end
  
    def rename_children(children, part_to_rename, name)
      children.each do |mb|
    		parts = mb.full_name.split('.')
        parts[part_to_rename] = name
    		new_name = parts * '.'
    		status = JoyentMaildir::Base.connection.mailbox_rename(mb.id, new_name)
    		mb.update_attributes :full_name		=> new_name,
    											   :uid_validity => status[:uidvalidity],
    											   :uid_next			=> status[:uidnext]
  											
    		rename_children(mb.children, part_to_rename, name)
  		end
    end
end