=begin #(fold)
++
Copyright 2004-2007 Joyent Inc.

Redistribution and/or modification of this code is 
governed by the GPLv2.

Report issues and contribute at http://dev.joyent.com/

$Id$
--
=end #(end)


class JoyentFileType
  attr_accessor :regex, :preview_type, :css_class, :description, :mime_type
  
  # takes either a file extension that will be matched to the first regex, or all 5 parameters
  def initialize(*args)
    if args.size == 1
      args[0] ||= ''
      args[0] = args[0].downcase
      args = @@types.detect{|t| t[0] == args[0]} || @@types[-1]
    end
    @regex, @preview_type, @css_class, @description, @mime_type = args
  end
  
  def previewable?
    [:image, :text, :html].include?(@preview_type)
  end

  # NOTE: adding a new description here requires adding the string to i18n_do_not_include.rb + maybe having a new icon drawn
  # run this from the console for faster service: puts JoyentFileType.types.collect{|t| "_('#{t[3]}')"}.uniq.sort
  # ['extension', :preview_type, 'css class', _('Description'), 'mime/type']
  @@types = [
    # graphics
    ['jpeg', :image, 'jpg', 'Image',           'image/jpeg'],
    ['jpg',  :image, 'jpg', 'Image',           'image/jpeg'],
    ['gif',  :image, 'gif', 'Image',           'image/gif'],
    ['png',  :image, 'png', 'Image',           'image/png'],
    ['bmp',  nil,    'bmp', 'Image',           'image/bmp'],
    ['raw',  nil,    'raw', 'Image',           'image/raw'],
    ['psd',  nil,    'psd', 'Photoshop Image', 'image/photoshop'],
    ['ai',  nil,    'ai', 'Illustrator Document', 'application/illustrator'],
    ['indd',  nil,    'indd', 'Indesign Document', 'application/x-indesign'],

    # 'office'
    ['vcf', nil,  'vcf', 'vCard',        'text/x-vcard'],
    ['ics', nil,  'ics', 'vCalendar',    'text/calendar'],
    ['doc', nil,  'doc', 'Document',     'application/msword'],
    ['wpd', nil,  'wpd', 'Document',     'application/wordperfect'],
    ['wp',  nil,  'wpd', 'Document',     'application/wordperfect'],
    ['qpw', nil,  'qpw', 'Document',     'application/x-quattropro '],
    ['ppt', nil,  'ppt', 'Presentation', 'application/vnd.ms-powerpoint'],
    ['xls', nil,  'xls', 'Spreadsheet',  'application/vnd.ms-excel'],
    ['pdf', :pdf, 'pdf', 'PDF Document', 'application/pdf'],

    # audio
    ['mp3', :quicktime, 'mp3', 'Audio', 'audio/mpeg'],
    ['wav', :quicktime, 'wav', 'Audio', 'audio/x-wav'],
    ['aac', :quicktime, 'aac', 'Audio', 'audio/x-aac'],
    ['m4a', :quicktime, 'm4a', 'Audio', 'audio/mpeg'],
    ['aiff',:quicktime, 'aiff','Audio', 'audio/aiff'],
    ['aif', :quicktime, 'aif', 'Audio', 'audio/aiff'],
    ['m4b', :quicktime, 'm4b', 'Audio', 'audio/mpeg'],
    ['m4p', :quicktime, 'm4a', 'Protected Audio', 'audio/mpeg'],

    # video
    ['mov',  :quicktime, 'mov',   'Video',       'video/quicktime'],
    ['wmv',  nil,        'wmv',   'Video',       'video/x-ms-wmv'],
    ['mpeg', :quicktime, 'video', 'Video',       'video/mpeg'],
    ['mp4',  :quicktime, 'video', 'Video',       'video/mp4'],
    ['mpg',  :quicktime, 'video', 'Video',       'video/mpeg'],
    ['flv',  :flash,     'fla', 'Flash Video', 'video/x-flv'],
    ['fla',  :flash,     'flv', 'Flash Video', 'video/x-fla'],

    # web
    ['html', :html, 'html',        'HTML Document',         'text/html'],
    ['htm',  :html, 'htm',         'HTML Document',         'text/html'],
    ['css',  :text, 'css', 'Cascading Style Sheet', 'text/css'],

    # code
    ['rb',  :text, 'code', 'Source Code', 'text/plain'],
    ['js',  :text, 'code', 'JavaScript',  'text/javascript'],
    ['c',   :text, 'code', 'Source Code', 'text/plain'],
    ['py',  :text, 'code', 'Source Code', 'text/plain'],
    ['tex', :text, 'code', 'TeX',         'application/x-tex'],
    ['xsl', :text, 'code', 'Source Code', 'text/plain'],

    # misc
    ['txt',  :text,    'txt', 'Text',         'text/plain'],
    ['text', :text,    'txt', 'Text',         'text/plain'],
    ['',     :unknown, 'txt', 'Unknown Type', 'application/octet-stream']
  ]
  
  def self.types
    @@types
  end
end
