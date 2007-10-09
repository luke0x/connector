=begin #(fold)
++
Copyright 2004-2007 Joyent Inc.

Redistribution and/or modification of this code is 
governed by the GPLv2.

Report issues and contribute at http://dev.joyent.com/

$Id$
--
=end #(end)

class Folder < ActiveRecord::Base
  include JoyentGroup
  
  validates_presence_of :name

  has_many :joyent_files, :dependent => :destroy

  acts_as_tree :order => 'LOWER(folders.name)'

  def pathname
    # gross hack -- not particularly efficient but "works for now"
    p, path = self, []
    begin
      path.unshift p.name
    end while p = p.parent
    path * '/'
  end
  
  def add_file(file)
    joyent_file = self.joyent_files.create(:filename        => file.original_filename, 
                                           :organization_id => organization.id,
                                           :user_id         => owner.id, 
                                           :size_in_bytes   => file.size)  

    MockFS.file.open(joyent_file.path_on_disk, "w") do |f|
      f.write(file.read)
    end       
    
    joyent_file                             
  end  
  
  def add_file_from_disk(filename)
    full_path   = File.join(path_on_disk, filename)
    
    if MockFS.file.exist?(full_path)
      self.joyent_files.create(:filename        => filename, 
                               :organization_id => organization.id,
                               :user_id         => owner.id, 
                               :size_in_bytes   => File.size(full_path))                   
    end                 
  end
  
  def path_on_disk
    raise "No owner found" unless owner
    raise "No organization found" unless self.organization

    File.join(owner.root_path, pathname)
  end
  
  def rename!(new_name)
    update_path_on_disk { self.name = new_name }
  end

  def reparent!(new_parent)
    return if new_parent == self
    return if descendent?(new_parent)

    update_path_on_disk { self.parent = new_parent }
  end

  # Premature optimization is the new not prematurely optimising
  def cascade_permissions
    users = permissions.collect(&:user)
    children.each {|c| c.restrict_to!(users)}
    joyent_files.each {|jf| jf.restrict_to!(users)}
  end

  # is folder a descendent of me?
  def descendent?(folder)
    return false if folder.blank?
    return false if children.blank?
    return true if children.include?(folder)
    children.each do |child|
      return true if child.descendent?(folder)
    end
    return false
  end

  private
  
    def validate
      if owner # lame but will error if owner is nil
        documents_folder = owner.folders.find(:first, :conditions => ["folders.name = 'Documents' AND parent_id IS NULL"], :order => 'folders.id')
        if documents_folder and self.parent_id == documents_folder.id
          self.errors.add(:parent_id, "can not be the 'Documents' folder")
        end
      end
    end

    def update_path_on_disk(&blk)
      old_path = path_on_disk
      yield
      new_path = path_on_disk
      # rename on disk
      MockFS.file_utils.mv(old_path, new_path)
      self.save!
    end
end