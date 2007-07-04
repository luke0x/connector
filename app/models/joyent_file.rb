=begin #(fold)
Copyright 2004-2007 Joyent Inc.

Redistribution and/or modification of this code is governed
by either the GPLv2 or Joyent Commercial Software licenses.

Report issues and contribute at http://dev.joyent.com/

$Id$
=end #(end)

class JoyentFile < ActiveRecord::Base
  include JoyentItem
  
  validates_presence_of :filename
  validates_presence_of :size_in_bytes    
  validates_presence_of :folder_id
  validates_presence_of :joyent_file_type_description
  
  belongs_to  :message
  belongs_to  :folder
  
  before_validation :set_sort_caches
  before_save :ensure_uniqueness

  def self.search_fields
    [
      'users.username',
      'joyent_files.filename',
      'joyent_files.notes',
      'joyent_files.joyent_file_type_description'
    ]
  end
  
  def pathname
    File.join(folder.pathname, filename)
  end

  def filename_without_extension
    File.basename(filename, File.extname(filename))
  end
  
  def extension
    File.extname(filename) rescue ''
  end

  def extension_without_dot
    extension[1..-1]
  end
  
  def to_s
    filename
  end

  def joyent_file_type
    JoyentFileType.new(extension_without_dot)
  end
  
  def path_on_disk
    File.join(folder.path_on_disk, filename)
  end
  
  def move_to(new_folder)                                  
    if self.folder != new_folder && self.folder.owner == new_folder.owner
      old_path = path_on_disk
      self.folder= new_folder
      new_path = path_on_disk 
      self.save!
      MockFS.file_utils.mv(old_path, new_path)
    end
  end
  
  def copy_to(new_folder)
    new_file       = new_folder.joyent_files.create(self.attributes) 
    new_file.owner = new_folder.owner   
    new_file.save
    permissions.each {|perm| new_file.permissions.create(perm.attributes)} 
    
    MockFS.file_utils.cp(path_on_disk, new_file.path_on_disk)
    new_file
  end
  
  def remove!
    if MockFS.file.exist?(path_on_disk)
      MockFS.file.delete(path_on_disk)
    end
    destroy
  end

  def rename_without_extension!(new_name)
    old_path = path_on_disk

    self.filename = new_name + self.extension
    self.save!

    new_path = path_on_disk 
    
    if old_path != new_path
      MockFS.file_utils.mv(old_path, new_path)
    end
  end

  def name
    filename
  end
  
  def preview_text
    file = MockFS.file.open(path_on_disk, 'r')
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
  
  def class_humanize
    'File'
  end
  
  private

    def ensure_uniqueness    
      existing_names = self.folder.joyent_files(true).reject{|file| file == self}.collect(&:filename)
    
      current_count  = 1  
      base_filename  = self.filename_without_extension
      base_extension = self.extension

      while existing_names.index(self.filename)
        self.filename  = "#{base_filename}-#{current_count}#{base_extension}"
        current_count += 1
      end                                                         
    end

    def set_sort_caches
      self.joyent_file_type_description = self.joyent_file_type.description
    end

end