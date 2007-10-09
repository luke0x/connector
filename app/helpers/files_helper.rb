=begin #(fold)
++
Copyright 2004-2007 Joyent Inc.

Redistribution and/or modification of this code is 
governed by the GPLv2.

Report issues and contribute at http://dev.joyent.com/

$Id$
--
=end #(end)


module FilesHelper

  def file_preview(file)
    return '' unless file
    return '' unless file.joyent_file_type.previewable?

    out = ''
    out << "<div id=\"preview_show_trigger_#{file.id}\">"
      out << "<a href=\"#\" onclick=\"$('preview_show_trigger_#{file.id}').hide(); $('preview_hide_trigger_#{file.id}').show(); Effect.BlindDown('preview_#{file.id}', { duration: Joyent.effectsDuration}); return false;\" class=\"dinger addIconLeft\">" + _('Show Preview') + "</a>"
    out << "</div>"
    out << "<div id=\"preview_hide_trigger_#{file.id}\" style=\"display: none;\">"
      out << "<a href=\"#\" onclick=\"$('preview_hide_trigger_#{file.id}').hide(); $('preview_show_trigger_#{file.id}').show(); Effect.BlindUp('preview_#{file.id}', { duration: Joyent.effectsDuration}); return false;\" class=\"dingerExpanded addIconLeft \">" + _('Hide Preview') + "</a>"
    out << "</div>"
    out << "<div id=\"preview_#{file.id}\" style=\"display: none;\">"
      out << '<div style="overflow: auto; padding: 0.5em 0 0 0; max-height: 42em;">'
        out << case file.joyent_file_type.preview_type
        when :image
          image_tag_from_route(file_download_inline_url(:id => file.id), {:alt => ''})
        when :text
          simple_format(h(file.preview_text))
        when :html
          "<iframe src=\"#{file_download_inline_url(:id => file.id)}\"></iframe>"
        end
      out << '</div>'
    out << '</div>'
    out
  end

  def strongspace_file_preview(file)
    return '' unless file
    return '' unless file.joyent_file_type.previewable?

    out = ''
    out << "<div id=\"preview_show_trigger_#{file.id}\">"
      out << "<a href=\"#\" onclick=\"$('preview_show_trigger_#{file.id}').hide(); $('preview_hide_trigger_#{file.id}').show(); Effect.BlindDown('preview_#{file.id}', { duration: Joyent.effectsDuration}); return false;\" class=\"dinger addIconLeft\">" + _('Show Preview') + "</a>"
    out << "</div>"
    out << "<div id=\"preview_hide_trigger_#{file.id}\" style=\"display: none;\">"
      out << "<a href=\"#\" onclick=\"$('preview_hide_trigger_#{file.id}').hide(); $('preview_show_trigger_#{file.id}').show(); Effect.BlindUp('preview_#{file.id}', { duration: Joyent.effectsDuration}); return false;\" class=\"dingerExpanded addIconLeft \">" + _('Hide Preview') + "</a>"
    out << "</div>"
    out << "<div id=\"preview_#{file.id}\" style=\"display: none;\">"
      out << '<div style="overflow: auto; padding: 0.5em 0 0 0; max-height: 42em;">'
        out << case file.joyent_file_type.preview_type
        when :image
          image_tag_from_route(file_strongspace_download_inline_url(:owner_id => file.owner.id, :path => file.relative_path), {:alt => ''})
        when :text
          simple_format(h(file.preview_text))
        when :html
          "<iframe src=\"#{file_strongspace_download_inline_url(:path => file.relative_path)}\"></iframe>"
        end
      out << '</div>'
    out << '</div>'
    out
  end
  
  def service_file_preview(file)
    return '' unless file
    return '' unless file.joyent_file_type.previewable?

    out = ''
    out << "<div id=\"preview_show_trigger_#{file.id}\">"
      out << "<a href=\"#\" onclick=\"$('preview_show_trigger_#{file.id}').hide(); $('preview_hide_trigger_#{file.id}').show(); Effect.BlindDown('preview_#{file.id}', { duration: Joyent.effectsDuration}); return false;\" class=\"dinger addIconLeft\">" + _('Show Preview') + "</a>"
    out << "</div>"
    out << "<div id=\"preview_hide_trigger_#{file.id}\" style=\"display: none;\">"
      out << "<a href=\"#\" onclick=\"$('preview_hide_trigger_#{file.id}').hide(); $('preview_show_trigger_#{file.id}').show(); Effect.BlindUp('preview_#{file.id}', { duration: Joyent.effectsDuration}); return false;\" class=\"dingerExpanded addIconLeft \">" + _('Hide Preview') + "</a>"
    out << "</div>"
    out << "<div id=\"preview_#{file.id}\" style=\"display: none;\">"
      out << '<div style="overflow: auto; padding: 0.5em 0 0 0; max-height: 42em;">'
        out << case file.joyent_file_type.preview_type
        when :image
          image_tag_from_route(file_service_download_inline_url(:file_id => file.id), {:alt => ''})
        when :text
          simple_format(h(file.preview_text))
        when :html
          "<iframe src=\"#{file_service_download_inline_url(:file_id => file.id)}\"></iframe>"
        end
      out << '</div>'
    out << '</div>'
    out
  end
end
