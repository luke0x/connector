=begin #(fold)
Copyright 2004-2007 Joyent Inc.

Redistribution and/or modification of this code is governed
by either the GPLv2 or Joyent Commercial Software licenses.

Report issues and contribute at http://dev.joyent.com/

$Id$
=end #(end)

require 'fileutils'

class FolderObserver < ActiveRecord::Observer
  def after_create(folder)
    MockFS.file_utils.mkdir_p folder.path_on_disk
  end
  
  def after_destroy(folder)
    MockFS.file_utils.rm_rf folder.path_on_disk
  rescue => e
    RAILS_DEFAULT_LOGGER.warn 'Problem in FolderObserver#after_destroy: ' + e.message
  end
end