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
require File.dirname(__FILE__) + '/../../lib/joyent_maildir/mail_parser'

class Message < ActiveRecord::Base 
  include JoyentItem

  validates_presence_of :mailbox_id
  validates_presence_of :size_in_bytes
  validates_presence_of :filename
  validates_presence_of :internaldate
  
  belongs_to :mailbox

  before_save :set_sort_caches

  serialize :sender
  serialize :recipients

  delegate    :cc,         :to => :maildir_message
  delegate    :bcc,        :to => :maildir_message
  delegate    :message_id, :to => :maildir_message
  
  MessageAttachment = Struct.new :id, :name, :data, :mime_type
  
  def self.search_fields
    [
      'users.username',
      'messages.sender',
      'messages.recipients',
      'messages.subject',
      'messages.date',
      'messages.status'
    ]
  end
  
  def maildir_message
    @maildir_message ||= JoyentMaildir::Base.connection.message_maildir_message self.id
  end
  
  def body(text_only=false)
    JoyentMaildir::Base.connection.message_body self.id, text_only
  end
  
  def update_time!(time=nil)
    time ||= internaldate                                         
    
    JoyentMaildir::Base.connection.message_update_time self.id, time
  end
  
  def from
    sender || []
  end
  
  def to
    recipients || []
  end
  
  def part_for_id(part_id, sparts=nil)
    (sparts || maildir_message.parts).each do |p|
      if p[:multipart].nil?
        if p[:header].has_key?('content-id') && p[:header]['content-id'].any? {|x| x == "<#{part_id}>"}
          if p[:encoding] == 'base64'
            return Base64.decode64(p[:body])
          else
            return p[:body]
          end
        end
      else
        return part_for_id(part_id, p[:parts])
      end
    end
    nil
  end
    
  def delete!
    begin
      JoyentMaildir::Base.connection.message_delete self.id
    rescue JoyentMaildir::MaildirFileNotFound
    end
    
    destroy
  end
  
  def copy_to(dest_mailbox)
    begin
      JoyentMaildir::Base.connection.message_copy_to(self.id, dest_mailbox.id)
    rescue JoyentMaildir::MaildirFileNotFound
      # If this file is gone, well, it's gone.
    end      
  end
  
  def move_to(dest_mailbox)
    begin
      JoyentMaildir::Base.connection.message_move_to(self.id, dest_mailbox.id)
    rescue JoyentMaildir::MaildirFileNotFound
      # If this file is gone, well, it's gone.
    end
    
    update_attribute :active, false
  end
  
  def seen!
    unless seen?
      JoyentMaildir::Base.connection.message_seen self.id
      update_attribute :seen, true
    end
  end

  def flag!
    JoyentMaildir::Base.connection.message_flag self.id
    update_attribute :flagged, true
  end

  def unflag!
    JoyentMaildir::Base.connection.message_unflag self.id
    update_attribute :flagged, false
  end
  
  def draft!
    JoyentMaildir::Base.connection.message_draft self.id
    update_attribute :draft, true    
  end
  
  def answered!
    JoyentMaildir::Base.connection.message_answered self.id
    update_attribute :answered, true
  end
  
  def forwarded!
    JoyentMaildir::Base.connection.message_forwarded self.id
    update_attribute :forwarded, true
  end

  def name
    subject
  end
  
  def multipart?
    maildir_message.multipart || maildir_message.respond_to?(:filename)
  end

  def exist?
    if JoyentMaildir::Base.connection.message_exist?(self.id)
      true
    else
      self.update_attribute :active, false
      false
    end
  end
  
  def attachments
    return [] unless multipart?
    as = []
    if maildir_message.respond_to?(:filename)
      # The message *is* the attachment - some kind of microsoft crap
      [maildir_message.instance_values['table'].merge(:id => 0)]
    else
      maildir_message.parts.each do |part|
        potential_attachments = attachments_for_part(part)
        as += potential_attachments unless potential_attachments.nil?
      end
      cnt = 0
      as.map {|a| a[:id] = cnt; a[:filename]; cnt +=1; a}
    end
  end
  
  def attachments_for_part(part)
    if part[:filename]
      return [part]
    end
    if part[:type] == 'message'
      return [part.merge(:filename => 'email message')]
    end
    if part[:multipart]
      subparts = []
      part[:parts].each do |subpart|
        subparts += attachments_for_part(subpart)
      end
      return subparts
    end
    []
  end
  
  def attachment(idx)
    return nil unless multipart?
    attachment = attachments[idx.to_i]
    return nil if attachment.nil?
    
    if attachment[:type] == 'message'
      data = attachment[:message][:rawheader] + "\n\n" + attachment[:message][:body]
    elsif attachment[:encoding] == 'base64'
      data = Base64.decode64 attachment[:body]
    else
      data = attachment[:body]
    end
    
    MessageAttachment.new(idx, attachment[:filename] || 'email message', data, "#{attachment[:type]}/#{attachment[:subtype]}")
  end
  
  def full_path
    path = JoyentMaildir::MaildirPath.build(owner.organization.system_domain.email_domain, owner.username, mailbox.full_name)
    File.join(path, 'cur', filename)
  end
  
  def display_structure
    # If it's not multipart, just spit it back
    unless multipart?
      charset = maildir_message.charset || 'utf-8'
      return [['1', charset, maildir_message.encoding, maildir_message.subtype]]
    end
    
    # If it is multipart, build the display
    parts = maildir_message.parts.flatten.inject([]) do |arr, p|
      if p[:multipart]
        part = [arr.size, p[:parts][0][:charset], p[:parts][0][:encoding], p[:parts][0][:subtype]]
      else
        part = [arr.size, p[:charset], p[:encoding], p[:subtype]]
      end
      arr << part
      arr
    end
    
    # parts = display_r(body_structure.parts)
    # if parts.any? {|p| p.last == 'HTML'}
    #   parts.reject! { |p| p.last == 'PLAIN' }
    # end
    parts
  end
    

  def body_part(idx)
    return '' unless multipart?
    all_parts = maildir_message.parts.flatten#[idx][:body]
    if all_parts[idx][:multipart]
      all_parts[idx][:parts][0][:body]
    else
      all_parts[idx][:body]
    end
    
    # bodypart = idx.split('.').map{|x| x.to_i - 1}.inject(body_structure) { |acc, n| acc.parts.send(:at, n) }
    # data = owner.imap_connection.fetch_part(mailbox.id, self.id, idx)
    # if bodypart.encoding == 'QUOTED-PRINTABLE'
    #   data.gsub(/\r\n/, "\n").unpack("M").first
    # else
    #   data
    # end
  end
  
  def raw
    JoyentMaildir::Base.connection.message_raw self.id
  end
  
  def plain_only?
    !multipart? || maildir_message.parts.flatten.all? {|p| p[:subtype] && (p[:subtype].upcase == 'PLAIN')}
  end
  
  def has_html?
    multipart? && maildir_message.parts.flatten.any? {|p| p[:subtype] && (p[:subtype].upcase == 'HTML')}
  end

  REPLY_SUBJECT = /^re:/i
  FORWARD_SUBJECT = /fwd/i
  def build_reply_stub(all=false)
    msg = OpenStruct.new
    msg.to = normalize(self.from)
    if all
      msg.cc = normalize(self.to) + normalize(self.cc)
    else
      msg.cc = []
    end
    msg.bcc = []
    if self.subject =~ REPLY_SUBJECT
      msg.subject = Rfc2047.decode(self.subject || '')
    else
      msg.subject = "Re: #{Rfc2047.decode(self.subject || '')}"
    end
    
    msg.body = quote_body(self.body(true))
    msg.attachments = []
    msg
  end
  
  def build_forward_stub
    msg = OpenStruct.new
    msg.to  = []
    msg.cc  = []
    msg.bcc = []
    if self.subject =~ FORWARD_SUBJECT
      msg.subject = Rfc2047.decode(self.subject || '')
    else
      msg.subject = "Fwd: #{Rfc2047.decode(self.subject || '')}"
    end
    msg.body        = quote_body(self.body(false))
    msg.attachments = attachments
    msg
  end
  
  def build_draft_stub
    msg             = OpenStruct.new
    msg.to          = normalize(self.to)
    msg.cc          = normalize(self.cc)
    msg.bcc         = self.bcc || []
    msg.subject     = Rfc2047.decode(self.subject || '')
    msg.body        = self.body(false)
    msg.attachments = attachments
    msg
  end
  
  def from_addresses
    normalize(from) * "\n"
  end
  
  def to_addresses
    normalize(to) * "\n"
  end

  def statuses
    s = []
    s << 'Read'      if seen?
    s << 'Unread'    unless seen?
    s << 'Replied'   if answered?
    s << 'Flagged'   if flagged?
    s << 'Draft'     if draft?
    s << 'Forwarded' if forwarded?
    s << 'Spam'      if spam?
    s
  end

  def primary_status
    if self.draft?
      'Draft'
    elsif !self.seen?
      'Unread'
    elsif self.answered
      'Replied'
    elsif self.forwarded?
      'Forwarded'
    elsif self.flagged?
      'Flagged'
    elsif self.spam?
      'Spam'
    else
      'Read'
    end
  end
  
  def class_humanize
    'Email Message'
  end

  def spam?
    mailbox.full_name == 'INBOX.Spam'
  end

  private
  
    def plain_parts
      display_structure.inject('') do |str, p|
        str << body_part(p.first) if p.last == 'plain'
        str
      end
    end
  
    def normalize(array)
      array.collect{|email| "#{email.name} <#{email.address}>"} 
    end
  
    def quote_body(s)
      new_body = "On #{self.date}, #{normalize(self.from)} wrote:\n"
      new_body << s.split("\n").collect do |line|
        "> #{line}"
      end * "\n"
      new_body
    end
  
    def display_r(parts, level=1, levels=[])
      output = []
      parts.each_with_index do |part, idx|
        unless part.respond_to?(:parts)
          if levels.empty?
            partno = "#{idx + 1}"
          else
            partno = "#{levels.flatten * "."}.#{idx+1}"
          end
          charset = part.param.nil? ? 'US-ASCII' : part.param['CHARSET']
          output << ["#{partno}", charset, part.encoding, part.subtype] if displayable_part?(part)
        else
          # This part itself has parts, traverse them
          levels << idx + 1 unless level == 0
          output += display_r(part.parts, level+1, levels)
          levels.pop
        end
      end
      output
    end
  
    def attachment_parts(parts, level=1, levels=[])
      output = []
      parts.each_with_index do |part, idx|
        unless part.respond_to?(:parts)
          if levels.empty?
            partno = "#{idx + 1}"
          else
            partno = "#{levels.flatten * "."}.#{idx+1}"
          end
          if part.disposition.respond_to?(:dsp_type) && !part.param.nil? && ['ATTACHMENT', 'INLINE'].include?(part.disposition.dsp_type)
            output << MessageAttachment.new(partno, part.param['NAME'], nil, nil) unless part.param['NAME'].nil?
          end
        else
          # This part itself has parts, traverse them
          levels << idx + 1 unless level == 0
          output += attachment_parts(part.parts, level+1, levels)
          levels.pop
        end
      end
      output
    end
  
    def displayable_part?(part)
      return false if ['MIXED'].include?(part.subtype)
      if part.respond_to?(:disposition)
        if part.disposition.nil? || (part.disposition.respond_to?(:dsp_type) && part.disposition.dsp_type == 'INLINE')
          return true
        end
      end
      false
    end

    def set_sort_caches
      self.status = statuses.join(', ')
    end
    
    # This is for diagnostic purposes, use message.send(:parsed_message) to get it.
    def parsed_message
      JoyentMaildir::Base.connection.message_parsed_message self.id
    end
end
