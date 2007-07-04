=begin #(fold)
Copyright 2004-2007 Joyent Inc.

Redistribution and/or modification of this code is governed
by either the GPLv2 or Joyent Commercial Software licenses.

Report issues and contribute at http://dev.joyent.com/

$Id$
=end #(end)

class Mongrel::CleanBeforeHandler < Mongrel::HttpHandler
  def process(request, response)
    request.cgi.request["secret_file_path"] = nil
  end
end