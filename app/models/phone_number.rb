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
  
  @@providers = {
    :att           => 'txt.att.net',
    :cingular      => 'cingularme.com',
    :nextel        => 'messaging.nextel.com',
    :sprint        => 'messaging.sprintpcs.com',
    :tmobile       => 'tmomail.net',
    :verizon       => 'vtext.com',
    :virgin_mobile => 'vmobl.com'
  }
                  
  def self.providers
    @@providers
  end
  
  def provider_url
    @@providers[self.provider.to_sym]
  end
  
  # Used to confirm if the number is able to receive SMS via email
  # If the number matches, it saves as confirmed and returns true
  # Returns false if it does not confirm
  def confirm(number)
    self.confirmation_number == number.strip ? self.update_attribute(:confirmed, true) : false
  end
  
end
