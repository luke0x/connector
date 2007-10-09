=begin #(fold)
++
Copyright 2004-2007 Joyent Inc.

Redistribution and/or modification of this code is 
governed by the GPLv2.

Report issues and contribute at http://dev.joyent.com/

$Id$
--
=end #(end)

class Website < ActiveRecord::Base
#  validates_presence_of :person_id
  validates_presence_of :site_title
  validates_presence_of :site_url

  belongs_to :person

  before_save :transform_url
  after_save {|record| record.person.save if record.person}
  after_destroy {|record| record.person.save if record.person}
  
  private
  
    def transform_url
      unless site_url.blank? || site_url =~ /^http:\/\//
        self.site_url = "http://#{site_url}"
      end
    end
end