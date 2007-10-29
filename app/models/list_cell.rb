=begin #(fold)
++
Copyright 2004-2007 Joyent Inc.

Redistribution and/or modification of this code is 
governed by the GPLv2.

Report issues and contribute at http://dev.joyent.com/

$Id$
--
=end #(end)

require 'chronic'

class ListCell < ActiveRecord::Base
  include ApplicationHelper
  
  belongs_to :list_row
  belongs_to :list_column
  
  validates_presence_of :list_row_id
  validates_presence_of :list_column_id
  
  after_save {|record| record.list.save}
  
  def summed_value
    return 0 unless kind == 'Number'
    return value unless value == '+'

    descendent_cells = list_row.descendents.collect{|child_row| ListCell.find_by_row_and_column(child_row, list_column)}

    descendent_cells.inject(0) do |sum,cell|
      sum + cell.summing_value
    end
  end
  
  def summing_value
    return 0 if value.blank?
    return 0 unless kind == 'Number'
    return 0 if value == '+'
    value.to_num
  end        
  
  def value=(new_value)
    new_value = case self.kind
    when 'Checkbox' then new_value == 'true' ? 'true' : 'false'
    when 'Date'     then Chronic.parse(new_value)
    when 'Number'   then text_to_number(new_value)
    when 'Text'     then new_value
    end                      
    
    write_attribute(:value, new_value)
    new_value
  end

  def view_value
    case kind
    when 'Date'
      if value.blank?
        '&nbsp;'
      else
        Time.parse(value.to_s).strftime("%e %b %Y").strip rescue '&nbsp;'
      end
    when 'Number'
      if value == '+'
        "#{summed_value} (+)"
      else
        value.blank? ? '&nbsp;' : value
      end
    else
      value.blank? ? '&nbsp;' : value
    end
  end
  
  def self.find_by_row_and_column(list_row, list_column)
    raise "list_row not a ListRow" unless list_row.is_a?(ListRow)
    raise "list_column not a ListColumn" unless list_column.is_a?(ListColumn)

    if List.current
      List.current.list_rows.detect{|lr| lr.id == list_row.id}.list_cells.detect{|lc| lc.list_column_id == list_column.id}
    else
      ListCell.find(:first, :conditions => ["list_row_id = ? AND list_column_id = ?", list_row.id, list_column.id])
    end
  end
  
  def convert(from_kind, to_kind)
    return if     from_kind == to_kind
    return unless ListColumn::ColumnKinds.include?(from_kind)
    return unless ListColumn::ColumnKinds.include?(to_kind)
    
    new_value = case from_kind
    when 'Checkbox'
      case to_kind
      when 'Date'   then ''
      when 'Number' then value == 'true' ? '1' : '0'
      when 'Text'   then value == 'true' ? 'true' : 'false'
      end
    when 'Date'
      case to_kind
      when 'Checkbox' then 'false'
      when 'Number'   then ''
      when 'Text'     then value
      end
    when 'Number'
      case to_kind
      when 'Checkbox' then value == '1' ? 'true' : 'false'
      when 'Date'     then ''
      when 'Text'     then value
      end
    when 'Text'
      case to_kind
      when 'Checkbox'
        ['true', 't', 'yes', 'y', '1', '2'].include?(value.downcase) ? 'true' : 'false'
      when 'Date'
        text_to_date(value)
      when 'Number'
        text_to_number(value)
      end
    end   
    
    write_attribute(:value, new_value)
  end
  
  def ancestors
    list_row.ancestors.collect{|ancestor| ListCell.find_by_row_and_column(ancestor, list_column)}
  end
  
  # smart delegates
  # delegate :list, :to => :list_row
  # delegate :kind, :to => :list_column

  def list
    if List.current
      List.current
    else
      list_row.list
    end
  end
  
  def kind            
    return nil unless list_column
    
    if List.current
      List.current.list_columns.detect{|lc| lc.id == self.list_column_id}.kind
    else
      list_column.kind
    end
  end
  
  protected
    
    def text_to_date(val)
      format_date_time(Time.parse(val), false) rescue ''
    end
    
    def text_to_number(val)
      return if val.blank?
      return '' if val.strip.blank?
      return '+' if val.strip == '+'
      return '' unless val =~ /[0-9]+/
      val.to_num.to_s
    end
    
end