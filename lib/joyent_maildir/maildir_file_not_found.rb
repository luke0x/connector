=begin #(fold)
++
Copyright 2004-2007 Joyent Inc.

Redistribution and/or modification of this code is 
governed by the GPLv2.

Report issues and contribute at http://dev.joyent.com/

$Id$
--
=end #(end)

module JoyentMaildir
  class MaildirFileNotFound < RuntimeError
    include DRbUndumped

    def initialize(message, path)
      @message = message
      @path    = path
    end
    
    def to_s
      "message_id: #{@message.id}, path: #{@message.filename}, folder: #{@path}"
    end
  end
end