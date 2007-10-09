=begin #(fold)
++
Copyright 2004-2007 Joyent Inc.

Redistribution and/or modification of this code is 
governed by the GPLv2.

Report issues and contribute at http://dev.joyent.com/

$Id$
--
=end #(end)

require 'rubygems'
require 'insurance'

class PluginAnalyzer < Insurance::Analyzer
  #@@dir_regexp  = Regexp.new("^#{Dir.pwd}/(?:lib|app/(?:models|controllers))/")
  @@dir_regexp  = Regexp.new("^#{Dir.pwd}/lib")
  @@_path_cache = {}
  
  def self.filter(file)
    begin
      full_path =  @@_path_cache[file] || (@@_path_cache[file] = File.expand_path(file))
      if @@dir_regexp =~ full_path
        pwd = Dir.pwd
        return full_path[(full_path.index(pwd)+pwd.length+1)..-1]
      else
        return false
      end
    rescue
      return false
    end
  end
end