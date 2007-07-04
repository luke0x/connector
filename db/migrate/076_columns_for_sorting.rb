=begin #(fold)
Copyright 2004-2007 Joyent Inc.

Redistribution and/or modification of this code is governed
by either the GPLv2 or Joyent Commercial Software licenses.

Report issues and contribute at http://dev.joyent.com/

$Id$
=end #(end)

class ColumnsForSorting < ActiveRecord::Migration
  def self.up
    add_column :joyent_files, :joyent_file_type_description, :string
    JoyentFile.find(:all).each(&:save)
    add_column :people, :person_type, :string
    add_column :people, :primary_email, :string
    add_column :people, :primary_phone, :string
    Person.find(:all).each(&:save)
  end

  def self.down
    remove_column :joyent_files, :joyent_file_type_description
    remove_column :people, :person_type
    remove_column :people, :primary_email
    remove_column :people, :primary_phone
  end
end
