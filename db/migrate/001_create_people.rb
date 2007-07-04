=begin #(fold)
Copyright 2004-2007 Joyent Inc.

Redistribution and/or modification of this code is governed
by either the GPLv2 or Joyent Commercial Software licenses.

Report issues and contribute at http://dev.joyent.com/

$Id$
=end #(end)

class CreatePeople < ActiveRecord::Migration
  def self.up
    create_table :people do |t|
      t.column :name_prefix,  :string,  :default => ''
      t.column :first_name,   :string,  :default => ''
      t.column :middle_name,  :string,  :default => ''
      t.column :last_name,    :string,  :default => ''
      t.column :name_suffix,  :string,  :default => ''
      t.column :nickname,     :string,  :default => ''
      t.column :company_name, :string,  :default => ''
      t.column :title,        :string,  :default => ''
      t.column :icon_url,     :string,  :default => ''
      t.column :is_admin,     :boolean, :default => false, :null => false
      t.column :time_zone,    :string,  :default => ''
      t.column :notes,        :text,    :default => ''
      t.column :created_at,   :datetime
      t.column :updated_at,   :datetime
    end
  end

  def self.down
    drop_table :people
  end
end
