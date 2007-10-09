=begin #(fold)
++
Copyright 2004-2007 Joyent Inc.

Redistribution and/or modification of this code is 
governed by the GPLv2.

Report issues and contribute at http://dev.joyent.com/

$Id$
--
=end #(end)

class Mongrel::SendFileHandler < Mongrel::HttpHandler
  def process(request, response)
    if fts = response.file_to_send
      response.custom_reset
      stat = File.stat(fts.full_path)
      
      response.header["Content-Type"]= fts.content_type
      if fts.attachment
        response.header["Content-Disposition"] = "attachment; filename=\"#{fts.file_name}\""
  		end
  		
  		response.header['Content-Transfer-Encoding'] = 'binary'
  		response.status=200
  		response.send_status(stat.size)
  		
      response.send_header
  		response.send_file(fts.full_path)
    end
  end
end