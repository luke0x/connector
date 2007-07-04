=begin #(fold)
Copyright 2004-2007 Joyent Inc.

Redistribution and/or modification of this code is governed
by either the GPLv2 or Joyent Commercial Software licenses.

Report issues and contribute at http://dev.joyent.com/

$Id$
=end #(end)

class CreateReports < ActiveRecord::Migration
  def self.up
    create_table :reports do |t|
      t.column :report_description_id, :integer
      t.column :reportable_id,         :integer
      t.column :reportable_type,       :string 
      t.column :position,              :integer 
      t.column :organization_id,       :integer
      t.column :user_id,               :integer
      t.column :created_at,            :datetime
      t.column :updated_at,            :datetime
    end
  end

  def self.down
    drop_table :reports
  end
end
