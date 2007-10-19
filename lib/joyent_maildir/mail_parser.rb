=begin #(fold)
++
Copyright 2004-2007 Joyent Inc.

Redistribution and/or modification of this code is 
governed by the GPLv2.

Report issues and contribute at http://dev.joyent.com/

$Id$
--
=end #(end)

# $Id: mailparser.rb,v 1.18 2006/07/10 16:34:55 tommy Exp $
#
# Copyright (C) 2003-2006 TOMITA Masahiro
# tommy@tmtm.org
#

CP1252 = {159=>376, 148=>8221, 137=>8240, 154=>353, 132=>8222, 149=>8226, 138=>352, 155=>8250, 133=>8230, 150=>8211, 139=>8249, 128=>8364, 156=>339, 145=>8216, 134=>8224, 151=>8212, 140=>338, 146=>8217, 135=>8225, 152=>732, 130=>8218, 158=>382, 147=>8220, 136=>710, 153=>8482, 142=>381, 131=>402} unless defined? CP1252

def tidy_bytes(str)
  return nil if str.nil?
  str if str.unpack('U*')
rescue
  str.unpack('C*').map { |n|
    n < 128 ? n.chr : 
    n < 160 ? [CP1252[n] || n].pack('U') :
    n < 192 ? "\xC2" + n.chr : "\xC3" + (n-64).chr
  }.join
end

require "nkf"
require "date"
require 'ostruct'
require 'drb'
require 'time'

module JoyentMaildir
module MailParser
  class MailAddress
    include DRbUndumped
    attr_accessor :name, :address
    
    def initialize(str)
      str =~ /([^<>]*)(?:<([^<>]*)>)?/
      if $2.nil? # Address only
        @name    = nil
        @address = $1
      else
        @address = $2
        @name    = $1.strip.sub(/^"(.*)"$/, '\1')
      end
    end
    
    def to_s
      name.nil? ? @address : "#{@name} <#{@address}>"
    end
  end

  @@output_charset = "euc-jp"
  @@text_body_only = false
  @@extract_message_type = true

  ConvertMethods = {
    "JE" => :jistoeuc,
    "SE" => :sjistoeuc,
    "UE" => :utf8toeuc,
    "EU" => :euctoutf8,
    "SU" => :sjistoutf8,
    "JU" => :jistoutf8,
  } unless defined? ConvertMethods

  Charsets = {
    "iso-2022-jp" => "J",
    "euc-jp"      => "E",
    "shift_jis"   => "S",
    "sjis"        => "S",
    "x-sjis"      => "S",
    "utf-8"       => "U",
    "us-ascii"    => "N",
  } unless defined? Charsets

  module_function

  def euctoutf8(s)
    NKF.nkf("-m0Ewx", s)
  end

  def sjistoutf8(s)
    NKF.nkf("-m0Swx", s)
  end

  def jistoutf8(s)
    NKF.nkf("-m0Jwx", s)
  end

  def sjistoeuc(s)
    NKF.nkf("-m0Sex", s)
  end

  def jistoeuc(s)
    NKF.nkf("-m0Jex", s)
  end

  def utf8toeuc(s)
    NKF.nkf("-m0Wex", s)
  end

  def output_charset=(c)
    @@output_charset = c
  end

  def text_body_only=(f)
    @@text_body_only = f
  end

  def extract_message_type=(f)
    @@extract_message_type = f
  end

  def b64_hdecode(str)
    str.unpack("m")[0]
  end

  def b64_decode(str)
    str.unpack("m")[0]
  end

  def qp_hdecode(str)
    str.gsub("_", " ").gsub(/=([0-9A-F][0-9A-F])/no) do $1.hex.chr end
  end

  def qp_decode(str)
    str.gsub(/[ \t]+$/no, "").gsub(/=\r?\n/no, "").
      gsub(/=([0-9A-F][0-9A-F])/no) do $1.hex.chr end
  end

  def mdecode_token(s)
    if s !~ /\A=\?([a-z0-9_-]+)\?(Q|B)\?([^?]+)\?=\Z/nio then
      s
    else
      charset, encoding, text = $1, $2, $3
      fc = MailParser::Charsets[charset.downcase]
      if fc == nil then return s end
      if encoding.downcase == 'q' then
        s2 = qp_hdecode(text)
      else
        s2 = b64_hdecode(text)
      end
      tc = @@output_charset && MailParser::Charsets[@@output_charset.downcase]
      if fc == "N" or tc.nil? or fc == tc then return s2 end
      MailParser.send(MailParser::ConvertMethods[fc+tc], s2)
    end
  end

  def mime_header_decode(str)
    return str.gsub(/\s+/no, " ").gsub(/\?=\s+=\?/no, "?==?").gsub(/=\?[a-z0-9_-]+\?(Q|B)\?[^?]+\?=/nio){mdecode_token $&}
  end

  def trunc_comment(v)
    ret = ""
    after = v
    while not after.empty? and after =~ /^(\\.|\"(\\.|[^\\\"])*\"|[^\\\(])*/no do
      ret << $&
      after = $'
      if after =~ /^\(/no then
        a = trunc_comment_sub(after[1..-1])
        if a == nil then
          return ret+after
        end
        after = a
      end
      if after == "\\" then
        break
      end
    end
    ret+after
  end

  def trunc_comment_sub(orig)
    after = orig
    loop do
      if after =~ /^(\\.|[^\\\(\)])*/no then
        after = $'
      end
      if after =~ /^\)/no then
        return after[1..-1]
      end
      if after =~ /^\(/no then
        after = trunc_comment_sub(after[1..-1])
        if after == nil then
          return nil
        end
        next
      end
      return nil
    end
  end

  def split_address(v)
    a = []
    r = ""
    while not v.empty? do
      if v =~ /^(\s+|[0-9A-Za-z\!\#\$\%\&\'\*\+\-\/\=\?\^\_\`\{\|\}\~]+|\"(\\.|[^\\\"])*\")/ then
        r << $&
        v = $'
      elsif v[0] == ?, then
        a << r.strip
        r = ""
        v.slice!(0,1)
      else
        r << v.slice!(0,1)
      end
    end
    a << r.strip
    return a
  end

  def get_mail_address(v)
    v = trunc_comment(v)
    a = split_address(v)
    # TODO make a better address structure?
    z = a.map{|i| MailAddress.new(i.strip)} # =~ /<([^<>]*)>$/ ? $1 : i.strip}
    return z
  end

  def get_date(s)
    if s =~ /^[A-Z][A-Z][A-Z]\s*,\s*/i then
      s = $'
    end
    begin
      d = Time.parse s
    rescue ArgumentError
      d = Time.now
    end
    return unless d
    d.utc
  end

  def parse_content_type(str)
    hash = {}
    hash[:parameter] = {}
    if str.strip =~ /^([a-z0-9_-]+)(?:\/([a-z0-9_-]+))?\s*/nio then
      hash[:type] = $1.downcase
      hash[:subtype] = $2.downcase if $2
      params = $'	#'
      pending = {}
      pending_ext = {}
      while true do
        if params =~ /;\s*([a-z0-9_-]+)(?:\*(\d+))?\s*=\s*(?:\"((?:\\\"|[^\"])*)\"|([^\s\(\)\<\>\@\,\;\:\\\"\/\[\]\?\=]*))\s*/nio then
          pn, ord, pv = $1, $2, $3||$4
          params = $'
          if ord then
            pending[pn] = [] unless pending.key? pn
            pending[pn] << [ord.to_i, pv]
          else
            hash[:parameter][pn.downcase] = pv
          end
        elsif params =~ /;\s*([a-z0-9_-]+)\*\s*=\s*([a-z0-9_-]+)?\'(?:[a-z0-9_-]+)?\'(?:\"((?:\\\"|[^\"])*)\"|([^\s\(\)\<\>\@\,\;\:\\\"\/\[\]\?\=]*))\s*/nio then
          pn, charset, pv = $1, $2, $3||$4
          params = $'
          pending_ext[pn] = [[0, pv, charset]]
        elsif params =~ /;\s*([a-z0-9_-]+)\*0\*\s*=\s*([a-z0-9_-]+)?\'(?:[a-z0-9_-]+)?\'(?:\"((?:\\\"|[^\"])*)\"|([^\s\(\)\<\>\@\,\;\:\\\"\/\[\]\?\=]*))\s*/nio then
          pn, charset, pv = $1, $2, $3||$4
          params = $'
          pending_ext[pn] = [] unless pending_ext.key? pn
          pending_ext[pn] = [[0, pv, charset]]
        elsif params =~ /;\s*([a-z0-9_-]+)\*(\d+)\*\s*=\s*(?:\"((?:\\\"|[^\"])*)\"|([^\s\(\)\<\>\@\,\;\:\\\"\/\[\]\?\=]*))\s*/nio then
          pn, ord, pv = $1, $2, $3||$4
          params = $'
          pending_ext[pn] = [] unless pending_ext.key? pn
          pending_ext[pn] << [ord.to_i, pv]
        else
          break
        end
      end
      pending.each do |pn, pv|
        hash[:parameter][pn.downcase] = pv.sort{|a,b| a[0]<=>b[0]}.map{|a|a[1]}.join
      end
      pending_ext.each do |pn, pv|
        pv = pv.sort{|a,b| a[0]<=>b[0]}
        charset = pv[0][2]
        v = pv.map{|a|a[1].gsub(/%([0-9A-F][0-9A-F])/){$1.hex.chr}}.join
        fc = MailParser::Charsets[charset.downcase] if charset
        tc = @@output_charset && MailParser::Charsets[@@output_charset.downcase]
        if fc and fc != "N" and fc != tc then
          v = MailParser.send(MailParser::ConvertMethods[fc+tc], v)
        end
        hash[:parameter][pn.downcase] = v
      end
    end
    return hash
  end

  def parse_content_disposition(str)
    return parse_content_type(str)
  end

  def parse_message(msg)
    class << msg
      def _each_with_multiple_delimiter(delim=[])
        @found_boundary = false
        loop do
          @l = tidy_bytes(gets)
          if @l == nil then
            return
          end
          ll = @l.chomp
          if delim.include? ll then
            @found_boundary = true
            return
          end
          yield @l
        end
      end
      def last_line()
        @l && @l.chomp
      end
      attr_reader :found_boundary
    end

    m = parse_message2(msg)
    class << m
      def to_s()
        return <<EOS
From: #{self[:from].join(",")}
To: #{self[:to].join(",")}
Subject:#{self[:subject]}
Date: #{self[:date]}

#{self[:body]}

#{if self[:parts] then self[:parts].map{|p| "[#{p[:type]}/#{p[:subtype]}]<#{p[:filename]}>"}.join("\n") end}
EOS
      end
    end
    return m
  end

  def parse_message2(msg, boundary=[])
    ret = parse_header(msg, boundary)
    return ret if msg.found_boundary

    if ret[:type] == "message" and @@extract_message_type then
      m = parse_message2(msg, boundary)
      ret[:message] = m
    elsif ret[:multipart] and ret[:boundary] then
      parts = []
      b = ret[:boundary]
      bd = boundary + ["--"+b+"--", "--"+b]
      msg._each_with_multiple_delimiter(bd) do end	# skip preamble
      while msg.last_line == bd[-1] do
        m = parse_message2(msg, bd)
        parts << m
      end
      if msg.last_line == bd[-2] then
        msg._each_with_multiple_delimiter(boundary) do end
      end
      ret[:parts] = parts
    else
      if not @@text_body_only or ret[:type] == "text" or ret[:type].nil? then
        body = ""
        msg._each_with_multiple_delimiter(boundary) do |l|
          body << l 
        end
        ret[:body] = decode_body(body, ret[:encoding], ret[:charset])
      else
        msg._each_with_multiple_delimiter(boundary) do end
      end
    end
    return ret
  end

  def parse_header(msg, boundary=[])
    ret = {}
    raw = ""
    header = []
    msg._each_with_multiple_delimiter(boundary) do |l|
      l.chomp!
      break if l.empty?
      raw << l+"\n"
      if l =~ /^\s/no and not header.empty? then
        header[-1] << l
      elsif not l.include? ":"
        next			# skip garbage
      else
        header << l
      end
    end

    from = []
    to = []
    cc = []
    bcc = []
    date = nil
    subject = ""
    encoding = ct = charset = multipart = body = filename = bd = nil
    h = {}

    header.each do |str|
      hn, hb = str.split(/:\s*/no, 2)
      hn.downcase!
      h[hn] = [] unless h.key? hn
      h[hn] << mime_header_decode(hb)
      case hn.downcase
      when "from"
        from.concat get_mail_address(hb)
      when "to"
        to.concat get_mail_address(hb)
      when "cc"
        cc.concat get_mail_address(hb)
      when "bcc"
        bcc.concat get_mail_address(hb)
      when "date"
        date = get_date(hb)
      when "subject"
        subject.concat hb
      when "content-type"
        ct = parse_content_type(hb)
        if ct[:type] == "text" then
          charset = ct[:parameter]["charset"]
        elsif ct[:type] == "multipart" then
          multipart = true
          bd = ct[:parameter]["boundary"]
        end
        filename = mime_header_decode(ct[:parameter]["name"]) if ct[:parameter]["name"]
      when "content-disposition"
        cd = parse_content_disposition(hb)
        filename = mime_header_decode(cd[:parameter]["filename"]) if cd[:parameter]["filename"]
      when "content-transfer-encoding"
        encoding = hb.strip.downcase
      end
    end

    ret[:from] = from
    ret[:to] = to
    ret[:cc] = cc
    ret[:bcc] = bcc
    ret[:date] = date
    ret[:subject] = subject #mime_header_decode subject
    if ct then
      ret[:type] = ct[:type].downcase if ct[:type]
      ret[:subtype] = ct[:subtype].downcase if ct[:subtype]
      ret[:charset] = charset.downcase if charset
    end
    ret[:encoding] = encoding if encoding
    ret[:multipart] = multipart
    ret[:boundary] = bd
    ret[:filename] = filename if filename
    ret[:header] = h
    ret[:rawheader] = raw
    return ret
  end

  def decode_body(body, encoding, charset)
    return body
    case encoding
    when "base64"
      body = b64_decode body
    when "quoted-printable"
      body = qp_decode body
    end
    if charset == nil then return body end
    fc = MailParser::Charsets[charset.downcase]
    if fc == nil then return body end
    tc = @@output_charset && MailParser::Charsets[@@output_charset.downcase]
    if fc == "N" or tc.nil? or fc == tc then return body end
    MailParser.send(MailParser::ConvertMethods[fc+tc], body)
  end
end
end