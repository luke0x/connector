=begin #(fold)
++
Copyright 2004-2007 Joyent Inc.

Redistribution and/or modification of this code is 
governed by the GPLv2.

Report issues and contribute at http://dev.joyent.com/

$Id$
--
=end #(end)

# class -- service.name
# folder vs directory  

class Service
  include Comparable
  
  attr_reader :name, :root_path, :owner
  
  MANIFEST_FILENAME      = 'manifest.xml'
  SERVICE_DIRECTORY_NAME = '.services'
  
  def self.find(name, owner)
    root_path = File.join(owner.services_root_path, name)
    MockFS.file.exist?(root_path) ? Service.new(root_path, owner) : nil
  end
  
  def initialize(root_path, owner)
    @root_path, @owner, @name = root_path, owner, File.basename(root_path)
  end
  
  def root_folder
    return @root_folder if @root_folder
    return unless MockFS.file.exist?(self.manifest_file_path)
    
    begin
      root_element = XmlSimple.xml_in(MockFS.file.open(self.manifest_file_path).read, {'key_to_symbol' => true})
      @root_folder = ServiceFolder.parse_folder(root_element, nil, owner, self)
    rescue
      nil
    end
  end
  
  def manifest_file_path
    File.join(root_path, MANIFEST_FILENAME)
  end
  
  def <=>(other)
    self.name <=> other.name
  end
  
  def reload_manifest!
    @root_folder = nil
  end
  
  def find_file(id)
    root_folder.all_files.each{|file| return file if file.dom_id == id}
    nil
  end
  
  def find_folder(id)
    return root_folder if id.nil?
    root_folder.all_folders.each{|folder| return folder if folder.dom_id == id}
    nil
  end
end