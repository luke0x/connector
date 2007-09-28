=begin #(fold)
Copyright 2004-2007 Joyent Inc.

Redistribution and/or modification of this code is governed
by either the GPLv2 or Joyent Commercial Software licenses.

Report issues and contribute at http://dev.joyent.com/

$Id$
=end #(end)

class ImAddress < ActiveRecord::Base
#  validates_presence_of :person_id
  validates_presence_of :im_type
  validates_presence_of :im_address

  belongs_to :person

  after_save {|record| record.person.save if record.person}
  after_destroy {|record| record.person.save if record.person}

  TYPES = ['AIM', 'IRC', 'Google Talk', 'Jabber', 'MSN', 'Skype', 'Yahoo',  'Other']
end