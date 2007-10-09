=begin #(fold)
++
Copyright 2004-2007 Joyent Inc.

Redistribution and/or modification of this code is 
governed by the GPLv2.

Report issues and contribute at http://dev.joyent.com/

$Id$
--
=end #(end)

require 'fileutils'
require 'pathname'
require 'md5'

class ServiceFile
  class FileNotFound < Exception; end
  
  attr_reader :name, :path, :type, :folder, :owner, :service, :full_path, :dom_id

  alias :filename :name
  alias :relative_path :path
  alias :id :dom_id

  def initialize(name, path, type, folder, owner, service)
    @name      = name
    @path      = path
    @type      = type
    @folder    = folder
    @owner     = owner
    @service   = service
    @full_path = File.join(owner.services_root_path, service.name, path)
    @dom_id    = MD5.md5(@full_path)

    raise ServiceFile::FileNotFound unless MockFS.file.exist?(@full_path)
        
    @stat      = MockFS.file.stat(@full_path)
    folder.files << self if folder
  end

  def logical_path
    File.join(folder.logical_path, name)      
  end
  
  def path_on_disk
    Pathname.new(@full_path).realpath.to_s
  end
  
  def extension
    File.extname(@full_path) rescue ''
  end
  
  def joyent_file_type
    JoyentFileType.new(extension[1..-1])
  end
  
  def size_in_bytes
    @stat.size
  end
  
  def updated_at
    @stat.mtime
  end
  
  def created_at
    @stat.mtime
  end
  
  def name_with_extension
    File.extname(self.name).blank? ? self.name + self.extension : self.name
  end

  def preview_text
    file = MockFS.file.open(@full_path, 'r')
    lines = (1..5).collect do |n|
      begin
        file.readline
      rescue EOFError
        nil
      end
    end.compact
    file.close
    lines.join
  end
    
  def permissions
    []
  end

  def taggings
    []
  end
  
  def active_notifications
    []
  end
  
  def public?
    false  
  end
end