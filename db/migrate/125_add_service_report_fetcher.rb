=begin #(fold)
Copyright 2004-2007 Joyent Inc.

Redistribution and/or modification of this code is governed
by either the GPLv2 or Joyent Commercial Software licenses.

Report issues and contribute at http://dev.joyent.com/

$Id$
=end #(end)

class AddServiceReportFetcher < ActiveRecord::Migration
  def self.up
    ReportDescription.create :name => 'files_service' 
  end

  def self.down
    ReportDescription.find_by_name('files_service').destroy
  end
end
