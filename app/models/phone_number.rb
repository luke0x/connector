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
    :virgin_mobile => {
      :url => 'vmobl.com', 
      :text => 'Virgin Mobile'
    },
    :tmobile => {
      :url => 'tmomail.net', 
      :text => 'T-Mobile'
    },
    :att => {
      :url => 'txt.att.net', 
      :text => 'AT&T'
    },
    :sprint => {
      :url => 'messaging.sprintpcs.com', 
      :text => 'Sprint PCS'
    },
    :verizon => {
      :url => 'vtext.com', 
      :text => 'Verizon'
    },
    :nextel => { 
      :url => 'messaging.nextel.com', 
      :text => 'Nextel'
    }
  }

                  
  def self.providers
    @@providers
  end
  
  def provider_url
    @@providers[provider.to_sym][:url]
  end
  
  def provider_text
    @@providers[provider.to_sym][:text]
  end
  
  def sms_address
    return nil unless confirmed?
    num = phone_number.gsub(/[^0-9]/, '')
    "#{num[(num.length - 10), num.length]}@#{provider_url}"
  end
  
  # Used to confirm if the number is able to receive SMS via email
  # If the number matches, it saves as confirmed and returns true
  # Returns false if it does not confirm
  def confirm(number)
    confirmation_number == number.strip ? self.update_attribute(:confirmed, true) : false
  end 
  
end
