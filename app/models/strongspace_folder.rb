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

class StrongspaceFolder
  class FolderNotFound < Exception; end
  
  attr_reader :full_path
  attr_reader :user
  attr_reader :dom_id
  attr_reader :relative_path
  alias :owner :user
  alias :id :relative_path
  
  # owner - the person who owns the folder
  # path  - the relative path of the folder
  # user  - the user making the query - will differ from owner for guest access
  def self.find(owner, path, user)
    relative_path = File.join(*path)
    folder = new owner, relative_path
    if user.guest?
      folder.send(:set_guest_access!)
    end
    folder
  end
  
  # This is used by User#sftp_folder
  def self.find_root(user)
    new user, ''
  end

  # This is used by User#guest_folders
  def self.from_guest_path(guest_path)
    folder = new guest_path.owner, guest_path.relative_path
    folder.send(:set_guest_access!)
    folder
  end
  
  def self.create(owner, relative_path)
    RunAs.run_as(owner.uid, owner.organization.gid) do
      umask = File.umask 0007
      MockFS.file_utils.mkdir_p(File.join(owner.strongspace_root_path, relative_path))
      File.umask umask
    end
    new owner, relative_path
  end
  
  def self.blank
    OpenStruct.new(:relative_path => '', :children => [])
  end

  def initialize(owner, arelative_path)
    @user          = owner
    @relative_path = arelative_path
    @full_path     = File.join(owner.strongspace_root_path, relative_path)
    @dom_id        = MD5.md5(@full_path)
    
    raise StrongspaceFolder::FolderNotFound unless MockFS.file.exist?(@full_path)
    
    @guest_access  = false
  end
  
  def logical_path
    File.join('Strongspace', relative_path)
  end
  
  def relative_path
    @relative_path.sub(/^\//, '')
  end
  
  def destroy
    RunAs.run_as(@user.uid, @user.organization.gid) do
      MockFS.file_utils.rm_rf @full_path
    end
    self.freeze
    true
  end
  
  def rename!(new_name)
    return if relative_path.blank? # can't rename root folder
    
    parent = File.dirname @full_path
    new_full_path = File.join(parent, new_name)
    
    relative_parent = File.dirname relative_path
    new_relative_path = File.join(relative_parent, new_name)
    
    RunAs.run_as(@user.uid, @user.organization.gid) do
      MockFS.file_utils.mv @full_path, new_full_path
    end
    
    @full_path = new_full_path
    @relative_path = new_relative_path
    self
  end
  
  def reparent!(new_parent)
    return if self == new_parent
    return if descendent?(new_parent)

    RunAs.run_as(@user.uid, @user.organization.gid) do
      MockFS.file_utils.mv @full_path, new_parent.full_path
    end
  end
  
  # is folder a descendent of me?
  def descendent?(folder)
    return false unless folder.respond_to?(:relative_path)
    return false if folder.blank?
    return false if children.blank?
    return true if children.include?(folder)
    
    return true if relative_path.blank? # I'm root, everyone's a descendent
    return false if folder.relative_path.blank? # Root is no one's descendent
    
    folder.relative_path =~ /^#{relative_path}/
  end
  
  def ==(folder)
    folder.respond_to?(:full_path) && (Pathname.new(@full_path).cleanpath == Pathname.new(folder.full_path).cleanpath)
  end
  
  def children
    return [] if @guest_access
    
    child_folders = []
    MockFS.dir.entries(@full_path).each do |entry|
      next if entry.first == '.'
      if File.directory?(File.join(@full_path, entry))
        child_folders << self.class.new(@user, File.join(relative_path, entry))
      end
    end
    child_folders.sort_by{|f| f.name.downcase}
  end
  
  def parent
    return nil if relative_path.blank?
    self.class.new(@user, File.dirname(relative_path))
  end
  
  def user_id
    @user.id
  end
  
  def public?
    true
  end
    
  def name
    relative_path == '' ? 'Strongspace' : File.basename(@full_path)
  end
  
  def files
    return @files unless @files.blank?
    @files = []
    MockFS.dir.entries(@full_path).each do |entry|
      next if ['.', '..'].include?(entry)
      full_path = File.join(@full_path, entry)
      @files << StrongspaceFile.new(@user, File.join(relative_path, entry)) unless File.directory?(full_path)
    end
    @files.sort_by{|f| f.name.downcase}
  end
  
  def add_file(file)
    file_path = File.join(@full_path, file.original_filename)
    RunAs.run_as(@user.uid, @user.organization.gid) do
      umask = File.umask 0117
      MockFS.file.open(file_path, "w") do |f|
        f.write(file.read)
      end
      File.umask umask
    end
  end
  
  def pathname
    relative_path
  end

  def guest_paths
    GuestPath.find_all_by_relative_path(relative_path)
  end

  def guests_restricted?
    guest_paths.blank?
  end
  
  def remove_guest_access!
    guest_paths.map(&:destroy)
  end
  
  def grant_guest_access(user)
    raise "User is not a guest" unless user.guest?
    GuestPath.create(:relative_path => relative_path, :user_id => User.current.id, :guest_id => user.id)
  end
  
  def permission_for(guest)
    GuestPath.find_by_guest_id_and_user_id_and_relative_path(guest.id, @user.id, relative_path)
  end
  
  protected

    def set_guest_access!
      @guest_access = true
    end
end