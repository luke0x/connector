=begin #(fold)
Copyright 2004-2007 Joyent Inc.

Redistribution and/or modification of this code is governed
by either the GPLv2 or Joyent Commercial Software licenses.

Report issues and contribute at http://dev.joyent.com/

$Id$
=end #(end)

module ListsHelper
  
  def link_to_dinger(list_row)
    element_id = "#{list_row.dom_id}_dinger"

    if list_row.children.blank?
      link_class = ''
      link_to_function '&nbsp;', '', { :id => element_id, :class => "listDinger #{link_class}" }
    else
      link_to_function '&nbsp;', "ListRow.toggleExpanded('#{list_row.id}');", {:id => element_id, :class => "listDinger #{list_row.expanded? ? 'expanded' : 'collapsed'}"}
    end
  end
  
  def no_click_dinger(list_row)
    if list_row.children.blank?
      link_to_function '&nbsp;', '', { :class => "listDinger" }
    else
      link_to_function '&nbsp;', '', { :class => "listDinger #{list_row.expanded? ? 'expanded' : 'collapsed'}" }
    end
  end
  
  def render_list_cell(list_cell, new_row, peek=false)
    return '' if list_cell.blank?

    case list_cell.kind
    when 'Checkbox'
      check_box_tag('list_cell[value]',
                    'true',
                    determine_checked(list_cell.value),
                    { :onclick => "ListCell.updateCheckbox(#{list_cell.id});",
                      :id => list_cell.dom_id,
                      :disabled => ("disabled" unless User.current.can_edit?(list_cell.list) && ! peek),
                      :class => 'listEditable checkbox' }
                   )
    when 'Date', 'Number', 'Text'
      out = ''
      out << "<div id=\"#{list_cell.dom_id}\" new_row=#{new_row} class=\"listEditable #{list_cell.kind.downcase}\">#{list_cell.view_value}</div>"
      out << javascript_tag("ListCell.createIPE('#{list_cell.dom_id}', '#{list_cell_url(list_cell)}');")
      out
    end
  end
  
  def list_column_style(thing) # can be column or value
    return '' unless (thing.is_a?(ListColumn) or thing.is_a?(ListCell))
    style = ''

    # width for kind
    style << case thing.kind
    when 'Checkbox' then "width: #{24 + (thing.list.depth + 1) * 12}px; "
    when 'Date'     then 'width: 125px; '
    when 'Number'   then 'width: 125px; text-align: right; padding-right: 5px; '
    when 'Text'     then ' '
    end
  end
  
  def build_attrs(list_row)
    attrs = {}
    @list.list_columns_by_position.each_with_index do |list_column, index|
      attrs[list_column.name.gsub(' ', '')] = render_list_cell_opml(ListCell.find_by_row_and_column(list_row, list_column))
    end
    attrs
  end
  
  # Lame OPML export booleans
  def determine_checked(value)
    ['true','1','2'].include?(value) ? true : false
  end

end