=begin #(fold)
++
Copyright 2004-2007 Joyent Inc.

Redistribution and/or modification of this code is 
governed by the GPLv2.

Report issues and contribute at http://dev.joyent.com/

$Id$
--
=end #(end)

class ListFolderObserver < ActiveRecord::Observer
  def after_destroy(list_folder)
    # ensure the user always has 1 standard list folder
    if list_folder.owner.list_folders.select{|lf| lf.parent_id == nil}.blank?
      list_folder.owner.list_folders.create(:name => _('Lists'), :parent_id => nil)
    end
  end
end