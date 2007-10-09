=begin #(fold)
++
Copyright 2004-2007 Joyent Inc.

Redistribution and/or modification of this code is 
governed by the GPLv2.

Report issues and contribute at http://dev.joyent.com/

$Id$
--
=end #(end)

require 'md5'

class ServiceFolder
  class FolderNotFound < Exception; end
  
  attr_reader :name, :path, :parent, :owner, :service, :full_path, :dom_id, :children, :files
  
  alias :relative_path :path 
  alias :pathname :relative_path
  alias :id :dom_id

  def self.parse_folder(element, parent, owner, service)
    dname = element[:name].first rescue nil
    dpath = element[:path].first rescue nil
    
    current = ServiceFolder.new(dname, dpath, parent, owner, service)
    
    element[:directory].each do |directory|
      ServiceFolder.parse_folder(directory, current, owner, service)
    end if element[:directory]
    
    element[:file].each do |file|
      fname = file[:name].first rescue nil
      fpath = file[:path].first rescue nil      
      ftype = file[:type].first rescue nil      
      begin
        ServiceFile.new(fname, fpath, ftype, current, owner, service)
      rescue ServiceFile::FileNotFound
        # ignore the file
      end
    end if element[:file]
    
    current
  end
  
  def initialize(name, path, parent, owner, service)
    @name      = name
    @path      = path || name
    @parent    = parent
    @owner     = owner
    @service   = service
    @full_path = File.join(@owner.services_root_path, @service.name, relative_path)
    @dom_id    = MD5.md5(@full_path)
    @children  = []
    @files     = []
    
    parent.children << self if parent
  end
  
  def ==(folder)
    folder.respond_to?(:full_path) && (Pathname.new(@full_path).cleanpath == Pathname.new(folder.full_path).cleanpath)
  end

  # is folder a descendent of me?
  def descendent?(folder)
    return false if folder.blank?
    return false if children.blank?
    return true  if children.include?(folder)
    children.each do |child|
      return true if child.descendent?(folder)
    end
    return false
  end
  
  def all_files
    all_files = []
    all_files += @files  
    
    children.each{|child| all_files += child.all_files}
    all_files
  end
  
  def all_folders
    all_folders = []
    all_folders << self
    
    children.each{|child| all_folders += child.all_folders}
    all_folders
  end
  
  def logical_path
    parent_path = parent ? parent.logical_path : ''
    File.join(parent_path, name)  
  end
end