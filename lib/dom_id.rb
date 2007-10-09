=begin #(fold)
++
Copyright 2004-2007 Joyent Inc.

Redistribution and/or modification of this code is 
governed by the GPLv2.

Report issues and contribute at http://dev.joyent.com/

$Id$
--
=end #(end)

# jamis buck approved.. so no tests
# http://codefluency.com/articles/2006/05/30/rails-views-dom-id-scheme
# actually using: http://topfunky.net/svn/plugins/dom_id/lib/dom_id.rb since jamis' dashes aren't actually proper dom ids..
class ActiveRecord::Base
  def dom_id(prefix=nil)
    display_id = new_record? ? "new" : id
    prefix ||= self.class.name.underscore
    prefix != :bare ? "#{prefix.to_s.gsub(/\s+/, '_')}_#{display_id}" : display_id
  end
end