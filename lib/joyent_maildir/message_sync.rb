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
require File.dirname(__FILE__) + '/mail_parser'

module JoyentMaildir  
  class MessageSync
    include JoyentMaildir::Lockable
    
    def self.sync_for(mailbox)
      new(mailbox).sync_messages
    end
    
    def initialize(mailbox)
      @user     = mailbox.owner
      @mailbox  = mailbox
      @domain   = @user.organization.system_domain.email_domain
      @path     = MaildirPath.build(@domain, @user.username, @mailbox.full_name)
    end
    
    def sync_messages
      return unless obtain_lock(@path, 'connector.lock')
      
      move_new
      @curfiles = list_cur
      
      db_files = get_db_filenames # @mailbox.messages.find(:all).map(&:filename) # set D
      
      md_files = @curfiles.keys
      
      known    = db_files & md_files # set K
      gone     = db_files - known    # set G
      unknown  = md_files - known    # set U
      
      # Process set G
      mark_inactive(gone)
      
      # Process set K
      known.in_groups_of(50).map(&:compact).each do |filenames|
        ::Message.find_all_by_mailbox_id_and_filename(@mailbox.id, filenames).each do |proxy|
          update_status(proxy)
        end
      end
      
      # Process set U
      processed, unprocessed = joyent_id_scan(unknown)
            
      # Unprocessed mail is simple
      unprocessed.each do |filename|
        proxies = []
        begin
          proxies << create_proxy(filename, true)
        rescue Errno::ENOENT
        end
        # ::Message.import proxies, :validate => false
      end
      
      # Processed mail requires a bit more work
      processed.each do |filedata|
        proxies = []
        begin
          # Can't use import here because we need to know the IDs.  Import
          # doesn't give us that.
          proxies << create_proxy(filedata[:filename], true)
        rescue Errno::ENOENT
        end

        proxies.each do |proxy|
          clone_metadata(proxy, filedata[:jid]) unless proxy.nil?
        end
      end
      
    ensure
      release_lock
    end
    
    private    
    def move_new
      cur_dir = File.join(@path, 'cur')
      new_dir = File.join(@path, 'new')

      return unless MockFS.file.exist?(new_dir)
      
      RunAs.run_as(JoyentConfig.maildir_owner, JoyentConfig.maildir_group) do
        MockFS.dir.entries(new_dir).each do |mail|
          next if mail[0..0] == '.' # No '.', '..', or '.nfs...' files
          # Be sure to append :2, to the maildir name when going to cur/
          newname = File.join(cur_dir, "#{mail}:2,")
          MockFS.file_utils.mv(File.join(new_dir, mail), newname)
        end
      end
    end
    
    def get_db_filenames
      collector = []
      ::Message.connection.execute("SELECT filename FROM messages WHERE mailbox_id=#{@mailbox.id} AND active = 1").each do |row|
        collector << row[0]
      end
      collector
    end
    
    # Map from filename (basename) to the real file found in cur/
    # Skip files that start with '.'
    def list_cur
      RunAs.run_as(JoyentConfig.maildir_owner, JoyentConfig.maildir_group) do      
        MockFS.dir.entries(File.join(@path, 'cur')).inject({}) do |hsh, file|
          if file[0..0] != '.'
            filename = file.sub(/:2,D?F?P?R?S?T?$/, '')
            hsh[filename] = file
          end
          hsh
        end
      end
    end
    
    def mark_inactive(filenames)
      # Can speed this up with a raw UPDATE query
      filenames.in_groups_of(50).map(&:compact).each do |f|
        ::Message.find_all_by_mailbox_id_and_filename(@mailbox.id, f).each do |proxy|
          proxy.update_attribute :active, false
        end
      end
    end
    
    def update_status(proxy)      
      new_flags = {}
      from_file = {}
      
      flags = @curfiles[proxy.filename][/(D?F?P?R?S?T?)$/]
      from_file[:draft]       = flags.include?('D')
      from_file[:flagged]     = flags.include?('F')
      from_file[:forwarded]   = flags.include?('P')
      from_file[:answered]    = flags.include?('R')
      from_file[:seen]        = flags.include?('S')
      
      # This is so we only do a db update if something has changed
      new_flags[:draft]     = from_file[:draft]     unless from_file[:draft]     == proxy.draft?
      new_flags[:flagged]   = from_file[:flagged]   unless from_file[:flagged]   == proxy.flagged?
      new_flags[:forwarded] = from_file[:forwarded] unless from_file[:forwarded] == proxy.forwarded?
      new_flags[:answered]  = from_file[:answered]  unless from_file[:answered]  == proxy.answered?
      new_flags[:seen]      = from_file[:seen]      unless from_file[:seen]      == proxy.seen?
      
      # If it's been marked as trash, and we're active, it needs to be inactivated
      if flags.include?('T') && proxy.active?
        new_flags[:active] = false
      end
      
      proxy.update_attributes(new_flags) unless new_flags.empty?
    end
    
    def get_db_uids
      ::Message.connection.execute("SELECT uid FROM messages WHERE mailbox_id=#{@mailbox.id} AND active = 't'").map {|x| x.first.to_i}
    end

    def joyent_id_scan(filenames)
      processed = []
      unprocessed = []
      
      filenames.each do |filename|
        # It is possible that this file no longer exists when we try to process
        # it looking for the joyent id.  In that case, we'll just ignore it.
        # It will be caught on the next sync.
        begin
          jid = scan_file_for_joyent_id(filename)
        rescue Errno::ENOENT
          next
        end
        
        if jid.nil?
          unprocessed << filename
        else
          processed << {:filename => filename, :jid => jid}
        end
      end
      [processed, unprocessed]
    end
    
    def scan_file_for_joyent_id(filename)
      file = @curfiles[filename]
      RunAs.run_as(JoyentConfig.maildir_owner, JoyentConfig.maildir_group) do      
        f = MockFS.file.open(File.join(@path, 'cur', file))
        until f.eof?
          line = f.readline
          # We only need to process the headers, so if we hit a blank line, we're
          # done with the headers, no reason to grep the whole file.
          if line.strip.blank?
            f.close
            return nil
          end
          if line =~ /^X-Joyent-Id: (.+)$/
            f.close
            return $1
          end
        end
      end
    end
    
    def clone_metadata(proxy, original_joyent_id)
      original = @user.messages.find_by_joyent_id(original_joyent_id)
      unless original.nil?
        original.permissions.each {|p| proxy.permissions << p.clone}
        original.comments.each    {|c| proxy.comments    << c.clone}
        original.tags.each        {|t| @user.tag_item proxy, t.name}
      end
    end
    
    def tag_message(filename)
      uuid      = UUID.create.to_s

      message_path = File.join(@path, 'cur', @curfiles[filename])
      temp_dir     = File.join(@path, 'tmp')
      temp_path    = File.join(temp_dir, @curfiles[filename])

      
      RunAs.run_as(JoyentConfig.maildir_owner, JoyentConfig.maildir_group) do
        unless MockFS.file.exist?(temp_dir)
          MockFS.file_utils.mkdir(temp_dir)
        end
      end

      # Header append/replace really shouldn't be that hard.
      header = []
      body   = ''
      RunAs.run_as(JoyentConfig.maildir_owner, JoyentConfig.maildir_group) do
        f = MockFS.file.open(message_path)
        until f.eof?
          l = f.readline
          if l.strip.blank?
            body = f.read
            break
          end
          header << l
        end
        begin
          f.close
        rescue Errno::ESTALE
          # Don't know why this happens yet, stopgap fix
        end
      end
      
      header.reject! {|h| h =~ /^X-Joyent-Id:/}
      
      header << "X-Joyent-Id: #{uuid}\n"
      
      RunAs.run_as(JoyentConfig.maildir_owner, JoyentConfig.maildir_group) do
        f = MockFS.file.open(temp_path, 'w')
        f.write header.join
        f.write("\n")
        f.write(body)
        f.close

        MockFS.file_utils.mv(temp_path, message_path)
      end
      
      [uuid, header.join]
    end
    
    # Need:
    #  subject
    #  sender
    #  recipients
    #  date    
    #  seen?
    #  flagged?
    #  size in bytes
    #  internal date
    #  has attachments
    def message_data(header, filename)
      message_path  = File.join(@path, 'cur', @curfiles[filename])
      parsed_header = JoyentMaildir::MailParser.parse_message MockFS.file.open(message_path)
      data          = {}
      
      data[:subject]    = parsed_header[:subject]
      data[:date]       = parsed_header[:date]
      data[:sender]     = parsed_header[:from]
      data[:recipients] = parsed_header[:to]
      
      data[:has_attachments] = has_attachments?(parsed_header)
      
      # Parse the statuses off the command line and set thingies
      flags = @curfiles[filename][/(D?F?P?R?S?T?)$/]
      data[:draft]       = flags.include?('D')
      data[:flagged]     = flags.include?('F')
      data[:forwarded]   = flags.include?('P')
      data[:answered]    = flags.include?('R')
      data[:seen]        = flags.include?('S')
      
      # Size in bytes and internal date come from stat
      message_path = File.join(@path, 'cur', @curfiles[filename])
      stat = nil
      RunAs.run_as(JoyentConfig.maildir_owner, JoyentConfig.maildir_group) do
        stat = File::Stat.new(message_path)
      end
      data[:internaldate]  = stat.ctime
      data[:size_in_bytes] = stat.size

      data
    end
    
    def create_proxy(filename, create = false)
      # Don't create proxies for things that are deleted (trashed)
      flags = @curfiles[filename][/(D?F?P?R?S?T?)$/]
      return nil if flags.include?('T')
      
      new_jid, header = tag_message filename
      attrs = message_data(header, filename)
      method_to_use = create ? :create : :new
      msg = ::Message.send(method_to_use, attrs.merge({:owner           => @user,
                                                       :mailbox      => @mailbox,
                                                       :organization => @user.organization,
                                                       :joyent_id    => new_jid,
                                                       :filename     => filename,
                                                       :created_at   => Time.now,
                                                       :updated_at   => Time.now}))

      # A message gets its mailbox's permissions automatically.
      @mailbox.permissions.each {|p| msg.permissions << p.clone}
      msg
    end
    
    def has_attachments?(part)
      return true if part.has_key?(:filename)
      if part.has_key?(:parts)
        part[:parts].each do |p|
          return true if has_attachments? p
        end
      end
      false
    end
    
  end
end
