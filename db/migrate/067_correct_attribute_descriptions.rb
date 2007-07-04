=begin #(fold)
Copyright 2004-2007 Joyent Inc.

Redistribution and/or modification of this code is governed
by either the GPLv2 or Joyent Commercial Software licenses.

Report issues and contribute at http://dev.joyent.com/

$Id$
=end #(end)

class CorrectAttributeDescriptions < ActiveRecord::Migration
  def self.up
    (2..4).each do |id|
      SmartGroupAttributeDescription.create({
        "name"=>"Owner Username", "attribute_name"=>"owner_name", "smart_group_description_id"=>id
        })
    end
  end

  def self.down
  end
end
