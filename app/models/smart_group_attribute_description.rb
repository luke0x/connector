=begin #(fold)
Copyright 2004-2007 Joyent Inc.

Redistribution and/or modification of this code is governed
by either the GPLv2 or Joyent Commercial Software licenses.

Report issues and contribute at http://dev.joyent.com/

$Id$
=end #(end)

class SmartGroupAttributeDescription < ActiveRecord::Base
  validates_presence_of :name
  validates_presence_of :smart_group_description_id

  belongs_to :smart_group_description
  has_many :smart_group_attributes, :dependent => :destroy
end
