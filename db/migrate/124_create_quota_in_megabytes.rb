=begin #(fold)
Copyright 2004-2007 Joyent Inc.

Redistribution and/or modification of this code is governed
by either the GPLv2 or Joyent Commercial Software licenses.

Report issues and contribute at http://dev.joyent.com/

$Id$
=end #(end)

class CreateQuotaInMegabytes < ActiveRecord::Migration
  def self.up
    add_column :quotas, :megabytes, :integer
    ActiveRecord::Base.connection.execute("update quotas set megabytes = (gigabytes * 1024)")
    remove_column :quotas, :gigabytes
  end

  def self.down
    add_column :quotas, :gigabytes, :integer
    ActiveRecord::Base.connection.execute("update quotas set gigabytes = (cast((megabytes / 1024) as integer))")
    remove_column :quotas, :megabytes
  end
end
