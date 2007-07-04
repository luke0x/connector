=begin #(fold)
Copyright 2004-2007 Joyent Inc.

Redistribution and/or modification of this code is governed
by either the GPLv2 or Joyent Commercial Software licenses.

Report issues and contribute at http://dev.joyent.com/

$Id$
=end #(end)

require 'net/smtp'
require 'action_mailer'
require 'mime/types'

class MailMessage < ActionMailer::Base
  cattr_accessor :smtp_host
  @@smtp_host  = JoyentConfig.smtp_host

  def self.save_joyent_mail(*params)
    new('joyent_mail', *params).save!
  end
  
  def joyent_mail(opts)
    @user        = opts[:user]
    
    @from        = opts[:params][:from]
    @recipients  = Array(opts[:params][:to])
    @cc          = Array(opts[:params][:cc])
    @bcc         = Array(opts[:params][:bcc])
    @subject     = opts[:params][:subject]
    @body        = opts[:params][:body]
    
    @in_reply_to = opts[:in_reply_to]
    
    @recipients += opts[:params][:to_field].split(',')  if opts[:params][:to_field]
    @cc         += opts[:params][:cc_field].split(',')  if opts[:params][:cc_field]
    @bcc        += opts[:params][:bcc_field].split(',') if opts[:params][:bcc_field]

    if opts[:original_message] && !opts[:original_message].plain_only? && !opts[:params][:eattachments]
      @deliver_raw_message = true
      @original_message    = opts[:original_message]
    end
    
    # Set up attachments and stuff
    opts[:params][:files] && opts[:params][:files].each do |file|
      if file.size > 0
        attachment :body         => file.read, 
                   :filename     => file.original_filename,
                   :content_type => MIME::Type.simplified(MIME::Types.of(file.original_filename).to_s)
      end
    end
    
    # Files from connector
    connector_files = []
    connector_files += opts[:params][:joyent_files].collect do |file_id|
      begin
        JoyentFile.find(file_id, :scope => :read)
      rescue ActiveRecord::RecordNotFound
      end
    end if opts[:params][:joyent_files]

    # Strongspace attachments
    connector_files += opts[:params][:strongspace_files].collect do |file_id|
      begin
        file = StrongspaceFile.find(@user, file_id.strip, @user)
      rescue ActiveRecord::RecordNotFound
      end
    end if opts[:params][:strongspace_files]

    connector_files.each do |file|
      attachment :body         => open(file.path_on_disk).read,
                 :filename     => file.name,
                 :content_type => MIME::Types.of(file.name).first.simplified
    end
        
    # Service attachments
    if opts[:params][:service] && service = Service.find(opts[:params][:service], @user)
      opts[:params][:service_files].collect.each do |file_id|
        begin
          file = service.find_file(file_id.strip)

          attachment :body         => open(file.path_on_disk).read,
                     :filename     => file.name_with_extension,
                     :content_type => MIME::Types.of(file.name_with_extension).first.simplified
        rescue ActiveRecord::RecordNotFound
        end
      end if opts[:params][:service_files]
    end
    
    # attachment.name/data/mime_type
    opts[:params][:eattachments] && opts[:params][:eattachments].each do |eattachment|
      file = opts[:original_message].attachment(eattachment)
      attachment :body         => file.data,
                 :filename     => file.name,
                 :content_type => file.mime_type
    end
  end
  
  # Override AM's create!, we don't need any templating jive.
  def create!(method_name, *parameters)
    initialize_defaults(method_name)
    send(method_name, *parameters)

    @mime_version ||= "1.0" if !@parts.empty?
    @mail = create_mail
    @mail.message_id = TMail::new_message_id
    @mail.references = [@mail.message_id]
    @mail.date       = Time.now
  end
  
  # Override AM's deliver!, we'll send via SMTP ourselves, and append to IMAP.
  # This translates to MailMessage.delver_joyent_mail
  def deliver!(mail=@mali)
    begin
      deliver_smtp
      return save_imap_sent
    rescue Exception => e
      RAILS_DEFAULT_LOGGER.error "******************* SMTP ERROR *******************"
      RAILS_DEFAULT_LOGGER.error "#{@@smtp_host} => #{e.to_s}"
      RAILS_DEFAULT_LOGGER.error "******************* SMTP ERROR *******************"
      return save_imap_draft
    end
  end
  
  # This translates to MailMessage.save_joyent_mail
  def save!
    save_imap_draft
  end
  
  private  

  def deliver_smtp
    host     = ENV['SMTP_HOST'] || JoyentConfig.smtp_host
    user     = ENV['SMTP_USER'] || nil
    pass     = ENV['SMTP_PASS'] || nil
    auth     = ENV['SMTP_AUTH'] || nil
    
    if @deliver_raw_message
      # Create a new tmail object using the raw image, then override the stuff
      # from @mail, then replace @mail with it.  This is used when sending a
      # html-ified draft.
      @tmail = TMail::Mail.parse(@original_message.raw)
      @tmail.to          = @mail.to
      @tmail.cc          = @mail.cc
      @tmail.bcc         = @mail.bcc
      @tmail.subject     = @mail.subject
      @mail              = @tmail
    end

    # XXX temp, need an smtp logger so we can see what gets called.  wrap it.
    unless ENV['RAILS_ENV'] == 'test'
      Net::SMTP.start(host, 25, host, user, pass, auth) do |smtp|
        smtp.send_message @mail.encoded, @mail.from, @mail.destinations
      end
    end
  end
  
  def save_imap_draft
    append_to_maildir('INBOX.Drafts')
  end
  
  def save_imap_sent
    append_to_maildir('INBOX.Sent')
  end
  
  def append_to_maildir(folder)
    mailbox      = @user.mailboxes.find_by_full_name(folder)
    encoded_mail = @mail.encoded
    
    data = JoyentMaildir::Base.connection.mailbox_append(mailbox.id, encoded_mail)
    
    # Handing back filename, joyent_id from mailbox_append, size_in_bytes, mailbox_id from here
    message = JoyentMaildir::MailParser.parse_message(StringIO.new(encoded_mail))
    
    data.merge({:size_in_bytes   => encoded_mail.size, 
                :mailbox_id      => mailbox.id,
                :subject         => message[:subject],
                :sender          => message[:from],
                :recipients      => message[:to],
                :date            => message[:date],
                :internaldate    => message[:date],
                :has_attachments => @parts.size > 0,
                :seen            => false
                })
    
    # FIXME need to store bcc somewhere
    #@user.imap_connection.flag(msg_id, "$Joyent:bcc:#{@mail.bcc.join(',')}") if @mail.bcc
  end
end
