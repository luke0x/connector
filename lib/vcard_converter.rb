=begin #(fold)
Copyright 2004-2007 Joyent Inc.

Redistribution and/or modification of this code is governed
by either the GPLv2 or Joyent Commercial Software licenses.

Report issues and contribute at http://dev.joyent.com/

$Id$
=end #(end)

class VcardConverter
  class << self
    def create_people_from_vcards(vcard_content)
      people = []
       
      # Parse the vcard file
      begin
        people = Vpim::Vcard.decode(vcard_content).collect do |vcard|
          person = Person.new
          
          person.first_name   = vcard.name.given 
          person.last_name    = vcard.name.family
          person.middle_name  = vcard.name.additional
          person.name_prefix  = vcard.name.prefix
          person.name_suffix  = vcard.name.suffix
          
          person.nickname     = vcard.nickname

          person.company_name = vcard.org.first if vcard.org
          person.title        = vcard.value('TITLE')
          
          vcard.emails.each do |vcard_email|
            email = EmailAddress.new
            
            email.email_address = vcard_email.to_s
            email.email_type    = vcard_email.location.last || vcard_email.nonstandard.last || 'Work'
            email.preferred     = vcard_email.preferred
            
            person.email_addresses << email
          end
          
          vcard.addresses.each do |vcard_address|
            address = Address.new
            
            address.street        = vcard_address.street 
            unless vcard_address.pobox.blank?
              address.street       += "\n#{vcard_address.pobox}" 
            end
            address.city          = vcard_address.locality       
            address.state         = vcard_address.region         
            address.postal_code   = vcard_address.postalcode     
            address.country_name  = vcard_address.country        
            address.address_type  = vcard_address.location.last       
            address.preferred     = vcard_address.preferred      
          
            person.addresses << address
          end
          
          vcard.telephones.each do |vcard_phone|
            phone = PhoneNumber.new
            phone.phone_number      = vcard_phone.to_s
            phone.phone_number_type = vcard_phone.location.last || vcard_phone.capability.last || vcard_phone.nonstandard.last
            phone.preferred         = vcard_phone.preferred
            
            person.phone_numbers << phone
          end
          
          if vcard.birthday
            special_date = SpecialDate.new
            
            special_date.special_date = vcard.birthday
            special_date.description  = 'Birthdate'
            
            person.special_dates << special_date
          end

          # The built in URL extractor was not working for me...I couldn't get the type          
          vcard.enum_by_name('URL').each do |vcard_url|
            website = Website.new
            
            website.site_url   = Vpim::decode_text(vcard_url.value)
            if vcard_url.pvalues('TYPE')
              website.site_title = vcard_url.pvalues('TYPE').last 
            end
            
            if !website.site_title || website.site_title.casecmp('pref') == 0
              website.site_title = 'homepage'
            end
            website.preferred  = vcard_url.pref?

            person.websites << website
          end
          
          ImAddress::TYPES.each do |im_type|
            vcard.enum_by_name("X-#{im_type.capitalize}").each do |vcard_im|
              im_address = ImAddress.new
              
              im_address.im_address = Vpim::decode_text(vcard_im.value)
              im_address.im_type    = im_type
              im_address.preferred  = vcard_im.pref?
              
              person.im_addresses << im_address
            end
          end
              
          person.notes = vcard.note
          
          # We will only store one icon for a user 
          if photo = vcard.photos.first  
            # Can't deal with a relative URL if that is what is supplied
            unless photo.respond_to?(:uri) && photo.uri =~ /^\//
              format = 'tiff'                                  
              if !photo.format.blank?
                format =  photo.format.gsub('/', '_') 
              end                                              
              begin
                person.add_icon(photo.to_s, format)
              rescue
                # Ignore an error from reading the photo  
              end
            end
          end

          person
       end
      rescue => e    
        raise "An error occurred while trying to parse the vcf file. (#{e.message})"
      end  
      
      people
    end
    
    def create_vcards_from_people(people)
      people = Array(people)
      people.collect do |person|
        Vpim::Vcard::Maker.make2 do |maker|
          maker.add_name do |name|
            name.family     = person.last_name.to_s
            name.given      = person.first_name.to_s
            name.additional = person.middle_name.to_s
            name.prefix     = person.name_prefix.to_s
            name.suffix     = person.name_suffix.to_s
          end
    
          maker.nickname = person.nickname unless person.nickname.blank?
          unless person.company_name.blank?
            maker.add_field(Vpim::DirectoryInfo::Field.create('ORG', "#{person.company_name}")) 
          end
          unless person.title.blank?
            maker.add_field(Vpim::DirectoryInfo::Field.create('TITLE', "#{person.title}")) 
          end
    
          person.email_addresses.each do |email|
            if !email.email_address.blank?
              maker.add_email(email.email_address) do |e| 
                e.location  = email.email_type
                e.preferred = email.preferred 
              end
            end
          end
    
          person.addresses.each do |address|
            maker.add_addr do |a|    
              a.street     = address.street.to_s
              a.locality   = address.city.to_s
              a.region     = address.state.to_s
              a.postalcode = address.postal_code.to_s
              a.country    = address.country_name.to_s
              a.location   = [address.address_type.to_s]
              a.preferred  = address.preferred
            end
          end
    
          person.phone_numbers.each do |number| 
            if !number.phone_number.blank?
              maker.add_tel(number.phone_number) do |p|
                p.location  = number.phone_number_type
                p.preferred = number.preferred
              end
            end
          end
    
          person.special_dates.each do |special_date|  
            if special_date.description =~ /^birth/i && !special_date.special_date.blank?      
              maker.birthday = special_date.special_date 
            end
          end
    
          person.websites.each do |website|
            if !website.site_url.blank?
              params = {'type' => []} 
              if website.site_title
                params['type'] << website.site_title
              end
              if website.preferred 
                params['type'] << 'pref' 
              end
              maker.add_field(Vpim::DirectoryInfo::Field.create('URL', website.site_url, params))
            end
          end
    
          # NOTE: May want to investigate add_impp 
          person.im_addresses.each do |im|
            if !im.blank?
              params = {}
              if im.preferred 
                params['type'] = 'pref' 
              end
              maker.add_field(Vpim::DirectoryInfo::Field.create("X-#{im.im_type.upcase}", im.im_address, params))
            end
          end
    
          unless person.notes.blank?
            maker.add_note(person.notes) 
          end
    
          if person.has_icon?
            maker.add_photo do |photo|
              photo.image = person.icon
              photo.type  = person.icon_type
            end
          end          
        end
      end.join("\n")
    end
  end
end