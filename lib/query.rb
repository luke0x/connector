=begin #(fold)
Copyright 2004-2007 Joyent Inc.

Redistribution and/or modification of this code is governed
by either the GPLv2 or Joyent Commercial Software licenses.

Report issues and contribute at http://dev.joyent.com/

$Id$
=end #(end)

class Query
  attr_reader :attributes, :search_text, :tags
  
  def initialize(text, attributes={}, tags=[], any=false)
    @search_text = text
    @attributes  = attributes
    @tags        = tags
    @any         = any
  end
  
  def any?
    @any
  end
  
  def to_s
    "(Query search_text=#{@search_text} any=#{@any} attributes=#{attributes.inspect})"
  end
  
  
  def self.from_smart_group(smart_group)
    body = ''
    attributes = smart_group.smart_group_attributes.inject({}) do |h, att|
      if att.smart_group_attribute_description.body?
        body = att.value
      else
        h[att.attribute_name] = att.value
      end
      h
    end
    if smart_group.smart_group_description.item_type
      attributes["item_type"]=smart_group.smart_group_description.item_type
    end
    any = smart_group.accept_any?
    
    new(body, attributes, smart_group.tags, any)
  end
  
  def self.query_for(search_text, item_type=nil)
    if item_type
      new(search_text, {"item_type"=>item_type})
    else
      new(search_text)
    end
  end
end
