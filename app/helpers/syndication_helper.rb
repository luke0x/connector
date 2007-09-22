=begin #(fold)
Copyright 2004-2007 Joyent Inc.

Redistribution and/or modification of this code is governed
by either the GPLv2 or Joyent Commercial Software licenses.

Report issues and contribute at http://dev.joyent.com/

$Id$
=end #(end)

module SyndicationHelper
  def calendar_link_for(event)
    # We have added the parameter of the date which is discarded simply to ensure uniqueness for repeated events
    external_event_show_url(:id=>event, :date => event.start_time_in_user_tz.strftime("%Y-%m-%d"), :only_path=>false)
  end    

  def files_link_for(file)
    if file.kind_of?(ServiceFile)
      files_service_show_url(:service_name => file.service.name, :file_id => file.id)      
    elsif file.kind_of?(StrongspaceFile)
      files_strongspace_show_url(:owner_id => file.owner.id, :path => file.relative_path)
    else
      external_file_show_url(:id=>file, :only_path=>false)
    end
  end
  
  def mail_link_for(message)
    external_message_show_url(:id=>message, :only_path=>false)
  end
  
  def feed_date(item)
    if item.is_a?(Message) && item.date
      item.date.rfc2822
    elsif item.respond_to?(:updated_at) && item.updated_at
      item.updated_at.rfc2822
    elsif item.respond_to?(:created_at) && item.created_at
      item.created_at.rfc2822
    else
      logger.info("unable to generate correct date for #{item.class}:#{item.id}")
      Time.now.rfc2822
    end
  end   

  def rss_item(item, xml)
    case item
    when Message    then render :partial => 'messages_rss',  :locals => { :messages  => [item], :xm => xml }
    when Event      then render :partial => 'events_rss',    :locals => { :events    => [item], :xm => xml }
    when Person     then render :partial => 'people_rss',    :locals => { :people    => [item], :xm => xml }
    when JoyentFile then render :partial => 'files_rss',     :locals => { :files     => [item], :xm => xml }
    when Bookmark   then render :partial => 'bookmarks_rss', :locals => { :bookmarks => [item], :xm => xml }
    when List       then render :partial => 'lists_rss',     :locals => { :lists     => [item], :xm => xml }
    else render :nothing => true
    end
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