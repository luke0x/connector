=begin #(fold)
Copyright 2004-2007 Joyent Inc.

Redistribution and/or modification of this code is governed
by either the GPLv2 or Joyent Commercial Software licenses.

Report issues and contribute at http://dev.joyent.com/

$Id$
=end #(end)

class PhoneNumber < ActiveRecord::Base
#  validates_presence_of :person_id
  validates_presence_of :phone_number_type
  validates_presence_of :phone_number

  belongs_to :person

  after_save {|record| record.person.save if record.person}
  after_destroy {|record| record.person.save if record.person}
end
