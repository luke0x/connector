=begin #(fold)
++
Copyright 2004-2007 Joyent Inc.

Redistribution and/or modification of this code is 
governed by the GPLv2.

Report issues and contribute at http://dev.joyent.com/

$Id$
--
=end #(end)

module Searchable
  def search_attributes
    sa = {}
    sa['orgid']      = organization.id.to_s
    sa['item_type']  = self.class.to_s
    sa['@uri']       = "#{self.class}:#{self.id}"
    sa['owner_name'] = self.owner.username

    sa['restricted_to'] = permissions.sort_by(&:user_id).collect{|p| ":#{p.user_id}:"}.to_s           if self.respond_to? :permissions
    sa['tagged_with']   = tags.collect(&:name).sort.collect{|t| ":%:#{t}:%:"}.to_s if self.respond_to? :tags

    sa.merge!(additional_search_attributes) if self.respond_to? :additional_search_attributes
    sa
  end

  def self.to_search_text(model, attributes)
    attributes.collect do |a|
      model.send(a)
    end * "\n"
  end

  def self.search_system=(sys)
    @@search_system = sys
  end

  def self.search_system
    @@search_system
  end
  
  def add_to_search_index
    JoyentJob::Job.new(self.class, self.id, :real_add_to_search_index).submit
  end
  
  def real_add_to_search_index
    Searchable.search_system.add_item(self)
  end
  
  @@search_system = TestSearchSystem.new
end