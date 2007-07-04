=begin #(fold)
Copyright 2004-2007 Joyent Inc.

Redistribution and/or modification of this code is governed
by either the GPLv2 or Joyent Commercial Software licenses.

Report issues and contribute at http://dev.joyent.com/

$Id$
=end #(end)

class AddSmartGroupSpecialConditions < ActiveRecord::Migration
  def self.up
    sgd = SmartGroupDescription.find_by_item_type("Message")
    [
      ["Date","date"]
    ].each do |pair|
      sgd.smart_group_attribute_descriptions.create({:attribute_name=>pair.last, :name=>pair.first})
    end

    sgd = SmartGroupDescription.find_by_item_type("Person")
    [
      ["Owner Username","owner_name"]
    ].each do |pair|
      sgd.smart_group_attribute_descriptions.create({:attribute_name=>pair.last, :name=>pair.first})
    end
  end

  def self.down
    sgd = SmartGroupDescription.find_by_item_type("Message")
    [
      ["Date","date"]
    ].each do |pair|
      sgad = sgd.smart_group_attribute_descriptions.find(:first, :conditions => [ "attribute_name = ? AND name = ?", pair.last, pair.first ])
      sgad.destroy if sgad
    end

    sgd = SmartGroupDescription.find_by_item_type("Person")
    [
      ["Owner Username","owner_name"]
    ].each do |pair|
      sgad = sgd.smart_group_attribute_descriptions.find(:first, :conditions => [ "attribute_name = ? AND name = ?", pair.last, pair.first ])
      sgad.destroy if sgad
    end
  end
end