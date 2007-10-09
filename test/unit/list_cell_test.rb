=begin #(fold)
++
Copyright 2004-2007 Joyent Inc.

Redistribution and/or modification of this code is 
governed by the GPLv2.

Report issues and contribute at http://dev.joyent.com/

$Id$
--
=end #(end)

require File.dirname(__FILE__) + '/../test_helper'

class ListCellTest < Test::Unit::TestCase
  fixtures all_fixtures
  include CRUDTest
  
  crud_data 'list_row_id'          => 1,
            'list_column_id'        => 1,
            'value'                 => "some random value"
            
  crud_required 'list_row_id', 'list_column_id'
  
  def setup
    User.current = users(:ian)  
  end

  def test_adjust_value_before_save
  end
  
  def test_touch_list_after_save
  end
  
  # class
  
  def test_find_by_row_and_column
    list_row = ListRow.find(1)
    list_column = ListColumn.find(1)

    list_cell = ListCell.find_by_row_and_column(list_row, list_column)
    assert_equal list_cell.list_row, list_row
    assert_equal list_cell.list_column, list_column

    assert_raises(RuntimeError) do
      ListCell.find_by_row_and_column(list_column, list_row)
    end
  end

  # instance
    
  def test_adjust_value
  end
  
  def test_convert_to!
  end
  
  def test_text_to_date
  end
  
  def test_text_to_number
  end
  
  def test_view_value
  end
  
end