=begin #(fold)
++
Copyright 2004-2007 Joyent Inc.

Redistribution and/or modification of this code is 
governed by the GPLv2.

Report issues and contribute at http://dev.joyent.com/

$Id$
--
=end #(end)

class SpecialDate < ActiveRecord::Base
#  validates_presence_of :person_id
  validates_presence_of :description
  validates_presence_of :special_date

  belongs_to :person

  after_save {|record| record.person.save if record.person}
  after_destroy {|record| record.person.save if record.person}
end