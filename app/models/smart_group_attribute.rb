=begin #(fold)
Copyright 2004-2007 Joyent Inc.

Redistribution and/or modification of this code is governed
by either the GPLv2 or Joyent Commercial Software licenses.

Report issues and contribute at http://dev.joyent.com/

$Id$
=end #(end)

class SmartGroupAttribute < ActiveRecord::Base
  validates_presence_of :value
  validates_presence_of :smart_group_id
  validates_presence_of :smart_group_attribute_description_id

  belongs_to :smart_group
  belongs_to :smart_group_attribute_description
  
  def attribute_name
    self.smart_group_attribute_description.attribute_name
  end
end
