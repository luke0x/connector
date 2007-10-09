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

class StrongspaceFile
  class FileNotFound < Exception; end
  
  attr_reader :full_path, :relative_path
  attr_reader :dom_id
  attr_reader :user
  alias :owner :user
  alias :id :dom_id
  
  # owner - the person who owns the file
  # path  - the relative path of the file
  # user  - the user making the query - will differ from owner for guest access
  def self.find(owner, path, user)
    relative_path = File.join(*path)
    new owner, relative_path
  end
    
  # relative_path => 'foo/bar/baz.txt'
  def initialize(owner, relative_path)
    @user          = owner
    @relative_path = relative_path.sub(/^\//, '')
    @full_path     = File.join(owner.strongspace_root_path, relative_path)
    @stat          = File.stat(@full_path)
    @dom_id        = MD5.md5(@full_path)
    raise StrongspaceFile::FileNotFound unless MockFS.file.exist?(@full_path)
  end
  
  def logical_path
    File.join('Strongspace', relative_path)  
  end
  
  def path_on_disk
    Pathname.new(@full_path).realpath.to_s
  end
  
  def data
    # TODO run as right here
    MockFS.file.open(@full_path, 'r').read
  end
  
  def name
    # TODO run as right here
    File.basename @relative_path
  end
  alias :filename :name
  
  def extension
    File.extname(@full_path) rescue ''
  end
  
  def rename_without_extension!(new_name)
    ext  = extension
    base = name
    dir  = File.dirname(@full_path)
    RunAs.run_as(@user.uid, @user.organization.gid) do
      MockFS.file_utils.mv(@full_path, File.join(dir, new_name + ext))
    end
  end
  
  def move_to(new_folder)
    RunAs.run_as(@user.uid, @user.organization.gid) do
      MockFS.file_utils.mv(@full_path, new_folder.full_path)
    end
  end
  
  def copy_to(new_folder)
    RunAs.run_as(@user.uid, @user.organization.gid) do
      MockFS.file_utils.cp(@full_path, new_folder.full_path)
    end
  end
  
  def remove!
    RunAs.run_as(@user.uid, @user.organization.gid) do
      MockFS.file.delete(@full_path)
    end
    self.freeze
    true
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
  
  def preview_text
    RunAs.run_as(@user.uid, @user.organization.gid) do
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
  end
  
  def taggings
    []
  end
  
  def permissions
    []
  end
  
  def public?
    false
  end
  
  def active_notifications
    []
  end
  
  def folder
    StrongspaceFolder.find(@user, File.dirname(@relative_path), @user)
  end
end