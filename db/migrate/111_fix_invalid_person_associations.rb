=begin #(fold)
++
Copyright 2004-2007 Joyent Inc.

Redistribution and/or modification of this code is 
governed by the GPLv2.

Report issues and contribute at http://dev.joyent.com/

$Id$
--
=end #(end)

class FixInvalidPersonAssociations < ActiveRecord::Migration
  def self.up
    # destroy nil items
    PhoneNumber.find(:all).select{|p| p.phone_number.blank?}.map(&:destroy)
    EmailAddress.find(:all).select{|e| e.email_address.blank?}.map(&:destroy)
    Address.find(:all).select{|a| (a.street.to_s + a.city.to_s + a.state.to_s + a.postal_code.to_s + a.country_name.to_s).strip.blank?}.map(&:destroy)
    ImAddress.find(:all).select{|i| i.im_address.blank?}.map(&:destroy)
    Website.find(:all).select{|w| w.site_url.blank? and w.site_title.blank?}.map(&:destroy)

    # fix 'fixable' items
    Website.find(:all).select{|w| w.site_url.blank? or w.site_title.blank?}.each do |w|
      w.site_title = w.site_url   if w.site_title.blank?
      w.site_url   = w.site_title if w.site_url.blank?
      w.save
    end
    SpecialDate.find(:all).select{|s| s.description.blank?}.each do |s|
      s.description = s.special_date.to_s
      s.save
    end

    # fix items that were only missing a type
    PhoneNumber.find(:all).select{|p|  p.phone_number_type.blank?}.each{|p| p.update_attributes(:phone_number_type => 'Home')}
    EmailAddress.find(:all).select{|e| e.email_type.blank?}.each{|e|        e.update_attributes(:email_type => 'Home')}
    Address.find(:all).select{|a|      a.address_type.blank?}.each{|a|      a.update_attributes(:address_type => 'Home')}
    ImAddress.find(:all).select{|i|    i.im_type.blank?}.each{|i|           i.update_attributes(:im_type => 'Home')}
  end

  def self.down
    # nada
  end
end