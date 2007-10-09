=begin #(fold)
++
Copyright 2004-2007 Joyent Inc.

Redistribution and/or modification of this code is 
governed by the GPLv2.

Report issues and contribute at http://dev.joyent.com/

$Id$
--
=end #(end)

require 'fileutils'

module JoyentMaildir
  class MailboxSync
    include JoyentMaildir::Lockable
    
    def self.specials
      ['INBOX.Trash', 'INBOX.Drafts', 'INBOX.Sent']
    end
    
    def self.sync_for(user)
      new(user).sync_mailboxes
    end
    
    def initialize(user)
      @user   = user
      @domain = user.organization.system_domain.email_domain
    end

    def sync_mailboxes
      ensure_maildir_exists

      return unless obtain_lock(MaildirPath.build(@domain, @user.username, 'INBOX'), 'connectormailbox.lock')
      sync_specials
      
      db_mailboxes = @user.mailboxes.find(:all)
      maildir_mailboxes = maildir_mailbox_hash
      
      # For mailboxes in imap that are not in the database we need to check
      # whether they are brand new mailboxes, or mailboxes that have been copied
      # or moved via imap.
      # 1.  If the message count is 0, must be treated as a new mailbox
      # 2.  Get the Joyent ID of the first message in the mailbox
      # 2a.  If there is no Joyent ID, consider it a new mailbox
      # 3.  Look up the Joyent ID in the database
      # 3a.  If the Joyent ID is not in the database, consider it a new mailbox
      # 4.  Verify the existence of the originating mailbox
      # 4a.  If the mailbox and message corresponding to the proxy do exist
      #      consider it a copied mailbox
      # 4b.  If the mailbox and message corresponding to the proxy do not exist
      #      consider it a moved mailbox
      maildir_mailbox_names = maildir_mailboxes.keys
      db_mailbox_names      = db_mailboxes.map(&:full_name)
      
      # Folders in imap that are not in the database
      targets = (maildir_mailbox_names - db_mailbox_names).sort_by {|fn| fn.count('.')}
      targets.each do |mailbox|
        if maildir_mailboxes[mailbox][:message_count] == 0
          # There are no messages in this mailbox, so there is no way we can
          # identify it as having been copied or move.  Just create the proxy
          # and move on.
          create_mailbox maildir_mailboxes[mailbox]
          next
        end
        
        # 2
        jid = maildir_mailboxes[mailbox][:joyent_id]
        if jid.blank?
          create_mailbox maildir_mailboxes[mailbox]
          next
        end
        
        # 3
        proxy = @user.messages.find_by_joyent_id(jid)
        if proxy.nil? # 3.a
          create_mailbox maildir_mailboxes[mailbox]
          next
        end
        
        # 4
        if maildir_mailboxes.keys.include?(proxy.mailbox.full_name)
          # 4a
          create_mailbox maildir_mailboxes[mailbox], proxy
        else
          # 4b
          create_mailbox maildir_mailboxes[mailbox], proxy
          proxy.mailbox.destroy
        end
      end
      
      # Folders that are in the database but not in imap, and have not been taken
      # care of by the move and copy checks.  These are assumed to have just been
      # deleted via imap.
      (db_mailbox_names - maildir_mailbox_names).each do |mailbox|
        db_mailbox = db_mailboxes.find {|d| d.full_name == mailbox}
        db_mailbox.destroy if db_mailbox
      end
    ensure
      release_lock
    end
    
    private
    def mailbox_info(path, full_name)
      # The algorithm needs:
      #  * Mailbox name
      #  * Message count
      #  * Joyent id of first message
      #  * uidvalidity (proxy creation)
      #  * uidnext     (proxy creation)
      entries = nil
      begin
        RunAs.run_as(JoyentConfig.maildir_owner, JoyentConfig.maildir_group) do
          entries = MockFS.dir.entries(File.join(path, 'cur'))
        end
      rescue Errno::ENOENT
        # Apparently, something isn't creating cur/ sometimes, so make sure
        # that it is there.
        RunAs.run_as(JoyentConfig.maildir_owner, JoyentConfig.maildir_group) do
          MockFS.dir.mkdir(File.join(path, 'cur'))
          MockFS.dir.mkdir(File.join(path, 'new')) unless MockFS.file.exist?(File.join(path, 'new'))
          MockFS.dir.mkdir(File.join(path, 'tmp')) unless MockFS.file.exist?(File.join(path, 'tmp'))
        end
        entries = []
      end
      
      entries.delete('.')
      entries.delete('..')
      
      if entries.size > 0
        first_msg = File.join(path, 'cur', entries.first)
        RunAs.run_as(JoyentConfig.maildir_owner, JoyentConfig.maildir_group) do
          jid = MockFS.file.open(first_msg).grep(/^X-Joyent-Id: (.+)$/) {$1}.first
        end
      else
        jid = nil
      end
      
      RunAs.run_as(JoyentConfig.maildir_owner, JoyentConfig.maildir_group) do
        begin
          uidvn = MockFS.file.open(File.join(path, 'courierimapuiddb')).readline
          uidv  = uidvn.split[1].to_i
          uidn  = uidvn.split[2].to_i
        rescue Errno::ENOENT, EOFError
          uidv = Time.now.to_i
          uidn = 1
          f = MockFS.file.open(File.join(path, 'courierimapuiddb'), 'w')
          f.write("1 #{uidv} #{uidn}\n")
          f.close
        end
      end
      
      { :full_name     => full_name,
        :message_count => entries.size,
        :joyent_id     => jid,
        :uid_validity  => Time.now.to_i,
        :uid_next      => 1 }
    end
    
    def buildbox(path, box)
      x = [box]
      RunAs.run_as(JoyentConfig.maildir_owner, JoyentConfig.maildir_group) do
        Dir.foreach(path) do |b|
          next if ['.', '..'].include?(b)
          next if b[-4..-1] == '.lck' # becuz nfs locks up in this
          next unless b[0..0] == '.'
          new_path = File.join(path, b)
          if File::stat(new_path).directory?
            x << buildbox(new_path, mailbox_info(new_path, "#{box[:full_name]}#{b}"))
          end
        end
      end
      x
    end
    
    def maildir_mailbox_hash
      path = MaildirPath.build(@domain, @user.username, 'INBOX')
      
      # Pull inbox info, build boxes hash
      buildbox(path, mailbox_info(path, 'INBOX')).flatten.inject({}) do |hsh, mb|
        hsh[mb[:full_name]] = mb
        hsh
      end
    end
    
    def create_mailbox(data, proxy=nil)
      data.delete(:message_count)
      data.delete(:joyent_id)
      
      if data[:full_name].count('.') > 0
        parent_name = data[:full_name].split('.')[0..-2].join('.')
        parent = @user.mailboxes.find_by_full_name(parent_name)
      else
        parent = nil
      end
      
      mailbox = @user.mailboxes.create(data.merge(:organization => @user.organization, :parent => parent))
      
      if proxy
        proxy.mailbox.permissions.each do |permission|
          mailbox.permissions << permission.clone
        end
      end
      mailbox
    end
    
    def sync_specials
      # Look for Special Folders (INBOX.Trash, INBOX.Drafts, INBOX.Sent).  If
      # they're not there in the maildir, create them and the proxies.
      self.class.specials.each do |special|
        path = MaildirPath.build(@domain, @user.username, special)
        RunAs.run_as(JoyentConfig.maildir_owner, JoyentConfig.maildir_group) do
          unless MockFS.file.exist?(path)
            # Not there, make it.
            md = JoyentMaildir::Mailbox.create(@user, special)
          end
        end
      end
    end
    
    def ensure_maildir_exists
      maildir = MaildirPath.build(@domain, @user.username, 'INBOX')
      RunAs.run_as(JoyentConfig.maildir_owner, JoyentConfig.maildir_group) do
        unless MockFS.file.exist?(maildir)
          # Not there, make it.
          # Create the Maildir structure
          ts = Time.now.to_i
        
          MockFS.file_utils.mkdir_p(maildir)
          ['cur', 'new', 'tmp'].each do |subdir|
            MockFS.dir.mkdir(File.join(maildir, subdir))
          end

          # Create the uid database
          f = MockFS.file.open(File.join(maildir, 'courierimapuiddb'), 'w')
          f.write("1 #{ts} 1\n")
          f.close
        end
      end
    end
  end
end