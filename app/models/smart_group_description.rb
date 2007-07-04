=begin #(fold)
Copyright 2004-2007 Joyent Inc.

Redistribution and/or modification of this code is governed
by either the GPLv2 or Joyent Commercial Software licenses.

Report issues and contribute at http://dev.joyent.com/

$Id$
=end #(end)

class SmartGroupDescription < ActiveRecord::Base
  validates_presence_of :name

  has_many :smart_group_attribute_descriptions, :order => 'LOWER(name)', :dependent => :destroy
  has_many :smart_groups, :dependent => :destroy

  def self.find_by_application_name(application_name)
    name = case application_name.downcase
    when 'connect'   then 'All Items'
    when 'mail'      then 'Messages'
    when 'calendar'  then 'Events'
    when 'people'    then 'People'
    when 'files'     then 'Files'
    when 'bookmarks' then 'Bookmarks'
    when 'lists'     then 'Lists'
    else
      nil
    end
    find_by_name(name)
  end
end