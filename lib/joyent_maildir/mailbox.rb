=begin #(fold)
++
Copyright 2004-2007 Joyent Inc.

Redistribution and/or modification of this code is 
governed by the GPLv2.

Report issues and contribute at http://dev.joyent.com/

$Id$
--
=end #(end)

require 'ostruct'
require 'fileutils'

module JoyentMaildir
  class Mailbox
    def initialize(mailbox)      
      @mailbox  = mailbox
      @username = mailbox.owner.username
      @domain   = mailbox.owner.organization.system_domain.email_domain
      
      @path = MaildirPath.build(@domain, @username, mailbox.full_name)
    end
    
    def self.create(user, mailbox)
      ts     = Time.now.to_i
      domain = user.organization.system_domain.email_domain
      path   = MaildirPath.build(domain, user.username, mailbox)
      inbox  = MaildirPath.build(domain, user.username, 'INBOX')
      
      # Create the Maildir structure
      begin
        MockFS.dir.mkdir(path)
      rescue Errno::EEXIST
        # seems like maybe a race condition between app and concurrent imap
        # access.  So, if it already exists then OK
      end
      
      ['cur', 'new', 'tmp'].each do |subdir|
        RunAs.run_as(JoyentConfig.maildir_owner, JoyentConfig.maildir_group) do
          begin
            MockFS.dir.mkdir(File.join(path, subdir))
          rescue Errno::EEXIST
            # Same as above
          end
        end
      end
      
      # Create the uid database
      RunAs.run_as(JoyentConfig.maildir_owner, JoyentConfig.maildir_group) do
        f = MockFS.file.open(File.join(path, 'courierimapuiddb'), 'w')
        f.write("1 #{ts} 1\n")
        f.close
      end
      
      # Subscribe to the mailbox
      # f = File.open(File.join(inbox, 'courierimapsubscribed'), 'a')
      # f.write("#{mailbox}\n")
      # f.close
      
      # FIXME touch maildirfolder?
      {:uidvalidity => ts, :uidnext => 1}
    end
    
    def self.empty_spam(user)
      domain = user.organization.system_domain.email_domain
      path = MaildirPath.build(domain, user.username, 'INBOX.Spam')

      Dir["#{path}/*"].each do |f|
       next if (f == '.' || f == '..')
       FileUtils.rm(f, :force => true)
      end
    end
    
    def self.empty_trash(user)
      domain = user.organization.system_domain.email_domain
      path = MaildirPath.build(domain, user.username, 'INBOX.Trash')
      
      Dir["#{path}/cur/*"].each do |f|
        next if (f == '.' || f == '..')
        RunAs.run_as(JoyentConfig.maildir_owner, JoyentConfig.maildir_group) do
          MockFS.file.delete(f)
        end
      end
    end
    
    def count
      not_deleted = entries.select     { |z| z =~ /,D?F?R?S?[^T]?$/ }
      unseen      = not_deleted.select { |z| z=~ /,D?F?R?[^S]?$/    }
      OpenStruct.new(:messages => not_deleted.size, :unseen => unseen.size)
    end
    
    def delete
      @entries = []
      RunAs.run_as(JoyentConfig.maildir_owner, JoyentConfig.maildir_group) do
        MockFS.file_utils.rm_rf(@path)
      end
    end
    
    def rename(to)
      dst = MaildirPath.build(@domain, @username, to)
      RunAs.run_as(JoyentConfig.maildir_owner, JoyentConfig.maildir_group) do
        MockFS.file_utils.mv @path, dst
      end
      
      # Unsubscribe from the old mailbox, subscribe to the new (in parent)
      # if @mailbox.parent.nil?
      #   orig_subfile = MaildirPath.build(@domain, @username, 'INBOX')
      # else
      #   orig_subfile = MaildirPath.build(@domain, @username, @mailbox.parent.full_name)
      # end
      # orig_subfile = File.join(orig_subfile, 'courierimapsubscribed')
      # 
      # dest_subfile = File.join(dst, '..', 'courierimapsubscribed')
      # 
      # # Remove from original subscribe file
      # if File.exist?(orig_subfile)
      #   s = File.open(orig_subfile).readlines
      #   s.reject! {|l| l.strip == @mailbox.full_name}
      #   f = File.open(orig_subfile, 'w')
      #   f.write s.join
      #   f.close
      # end
      # 
      # # Add to new subscribe file
      # f = File.open(dest_subfile, 'a')
      # f.write("#{to}\n")
      # f.close
      

      update_uiddb dst
    end
    
    # I implemented copy but we don't actually provide that capability.  Rather
    # than remove it entirely, I'll comment it out in case we ever do.
    # def copy(to)
    #   dst    = MaildirPath.build(@domain, @username, to)
    #   inbox  = MaildirPath.build(@domain, @username, 'INBOX')
    #   
    #   # Copy the maildir
    #   MockFS.file_utils.cp_r @path, dst
    #   
    #   # Subscribe to the mailbox
    #   f = File.open(File.join(inbox, 'courierimapsubscribed'), 'a')
    #   f.write("#{to}\n")
    #   f.close
    #   
    #   update_uiddb dst
    # end
    
    # TODO needs refactoring, it's been bloated up and i hate it
    def append(message)
      filename = MaildirPath.generate_file_name
      message_path = File.join(@path, 'cur', filename)

      uuid         = UUID.create.to_s
      RunAs.run_as(JoyentConfig.maildir_owner, JoyentConfig.maildir_group) do
        f = MockFS.file.open(message_path, 'w')
        header_written = false
        message.split(/\r?\n/).each do |line|
          if line.strip.blank? && !header_written
            f.write("X-Joyent-Id: #{uuid}\n")
            header_written = true
          end
          f.write "#{line}\n"
        end
        f.close      
      end
      
      {:filename => filename.sub(/:2,$/, ''), :joyent_id => uuid}
    end
    
    private
    def entries
      @entries ||= MockFS.dir.entries(File.join(@path, 'cur')).select {|e| !['.', '..'].include?(e)}
    end
    
    def update_uiddb(dst)
      uidv = Time.now.to_i
      
      # Reset the uidvalidity and uidnext.  We can use uiddb.size here because
      # UIDNEXT is the last UID + 1.  Uiddb has 1 extra element in it to hold
      # the header, so uiddb.size == (uiddb.size - 1 + 1).
      uiddb = nil
      RunAs.run_as(JoyentConfig.maildir_owner, JoyentConfig.maildir_group) do
        uiddb = MockFS.file.open(File.join(dst, 'courierimapuiddb')).readlines
        uiddb[0] = "1 #{uidv} #{uiddb.size}\n"
        uiddb[1..-1].each_with_index do |l, idx|
          uiddb[idx+1] = l.sub(/^\d+/, (idx+1).to_s)
        end
      
        f = MockFS.file.open(File.join(dst, 'courierimapuiddb'), 'w')
        f.write(uiddb.join)
        f.close
      end
      {:uidvalidity => uidv, :uidnext => uiddb.size}
    end
  end
end