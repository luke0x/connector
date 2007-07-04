=begin #(fold)
Copyright 2004-2007 Joyent Inc.

Redistribution and/or modification of this code is governed
by either the GPLv2 or Joyent Commercial Software licenses.

Report issues and contribute at http://dev.joyent.com/

$Id$
=end #(end)

class Tag < ActiveRecord::Base
  validates_presence_of   :name
  validates_presence_of   :organization_id
  validates_uniqueness_of :name, :scope => 'organization_id'
  
  has_many :taggings, :dependent => :destroy
  
  def items
    taggings.map(&:taggable)
  end
  
  def restricted_items
    # Collect all of the types that we need to get
    type_to_ids = {}
    self.taggings.each do |tagging|
      if !type_to_ids.has_key?(tagging.taggable_type)
        type_to_ids[tagging.taggable_type] = []
      end
      type_to_ids[tagging.taggable_type] << tagging.taggable_id
    end

    # Get the actual items through our 'restricted' filter
    items = []
    type_to_ids.each_pair do |type, ids|
      klass = Object.const_get(type)
      ids.each do |id|
        begin
          # TODO: this is slow, probably a way better way to do this
          items << klass.find(id, :scope => :org_read)
        rescue ActiveRecord::RecordNotFound
        end
      end
    end

    items
  end
  
  def <=>(right_tag)
    name <=> right_tag.name
  end
end