=begin #(fold)
++
Copyright 2004-2007 Joyent Inc.

Redistribution and/or modification of this code is 
governed by the GPLv2.

Report issues and contribute at http://dev.joyent.com/

$Id$
--
=end #(end)

class AddFolderTimestamps < ActiveRecord::Migration
  def self.up
    add_column "folders", "created_at", :datetime
    add_column "folders", "updated_at", :datetime       
    
    Folder.update_all("created_at = Now(), updated_at = Now()")
  end

  def self.down
    remove_column "folders", "created_at"
    remove_column "folders", "updated_at"
  end
end
                                                        