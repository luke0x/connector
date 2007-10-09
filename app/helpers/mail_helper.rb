=begin #(fold)
++
Copyright 2004-2007 Joyent Inc.

Redistribution and/or modification of this code is 
governed by the GPLv2.

Report issues and contribute at http://dev.joyent.com/

$Id$
--
=end #(end)

module MailHelper
  # escapes html + decodes so you don't have to
  def address_string(address, only_address=false)
    return '' if address.is_a?(String)
    return '' if address.nil?
    if address.name.blank? || only_address
      h(decode("#{address.address}"))
    else
      # FIXME This is a bug
      "<span title=\"<#{h(decode(address.address))}>\">#{h(decode(address.name))}</span>"
    end
  end                                        
  
  def compose_string(address)
    return address if address.is_a?(String)
    return '' if address.nil?
    if address.name.blank?
      h(decode(address.address))
    else
      "#{h(decode(address.name))} <#{h(decode(address.address))}>"
    end
  end
  
  def message_url(mailbox, message)
    case controller.action_name
    when 'notifications'
      mail_message_show_url(:mailbox => mailbox, :id => message.id)
    when 'special_list', 'special_show'
      mail_special_show_url(:mailbox => mailbox, :id => message.id)
    when 'list', 'show'
      mail_message_show_url(:mailbox => mailbox, :id => message.id)
    when 'smart_list', 'smart_show'
      mail_smart_show_url(:smart_group_id => @smart_group.url_id, :id => message.id)
    else
      mail_message_show_url(:mailbox => mailbox, :id => message.id)    
    end
  end
  
  def message_date(message, long=true)
    format_local_words_or_date(message.date) || _('Unavailable')
  end
    
  def decode(string)
    return '' if string.blank?
    Rfc2047.decode(string)
  end
  
  def html_for_display(message)
    html = sanitize_html(message.body)
    html.gsub!(/src="cid:([^"]+)"/) { |s| s = "src=\"/mail/inline/#{message.id}/#{$1}\"" }
    html.gsub!(/^%INLINE-(\d+)%$/) { |s| image_tag(mail_attachment_url(:message => message, :id => $1, :inline => 'y')) }
    html
  end

  def sanitize_html(html)
    # only do this if absolutely necessary
    if html.index("<")
      tokenizer = HTML::Tokenizer.new(html)
      new_text = ""
  
      while token = tokenizer.next
        node = HTML::Node.parse(nil, 0, 0, token, false)
        new_text << case node
          when HTML::Tag
            if ActionView::Helpers::TextHelper::VERBOTEN_TAGS.include?(node.name)
              node.to_s.gsub(/</, "&lt;")
            else
              if node.closing != :close
                node.attributes.delete_if { |attr,v| attr =~ ActionView::Helpers::TextHelper::VERBOTEN_ATTRS }
                if node.attributes["href"] =~ /^javascript:/i
                  node.attributes.delete "href"
                end
              end
              node.to_s
            end
          else
            node.to_s.gsub(/<([^!])/, "&lt;\\1")
        end
      end
  
      html = new_text
    end
  
    html
  end
end
