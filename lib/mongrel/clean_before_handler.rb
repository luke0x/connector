=begin #(fold)
++
Copyright 2004-2007 Joyent Inc.

Redistribution and/or modification of this code is 
governed by the GPLv2.

Report issues and contribute at http://dev.joyent.com/

$Id$
--
=end #(end)

class Mongrel::CleanBeforeHandler < Mongrel::HttpHandler
  def process(request, response)
    request.cgi.request["secret_file_path"] = nil
  end
end