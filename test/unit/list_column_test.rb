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

class ListColumnTest < Test::Unit::TestCase
  fixtures all_fixtures
  include CRUDTest

  crud_data 'list_id'     => 1,
            'name'        => "completed?",
            'kind'        => ListColumn::ColumnKinds.first,
            'position'    => 1
            
  crud_required 'list_id', 'name', 'kind'
  
  def setup
    User.current = users(:ian)
    @test_data = {:list_id  => 1,
                  :name     => "My column",
                  :kind     => ListColumn::ColumnKinds.last,
                  :position => 1}
  end

  def test_validate_known_kind
    @test_data[:kind] = "BrutalReality"
    list_column = ListColumn.new(@test_data)
    assert !list_column.valid?
    assert list_column.errors.on('kind')
    
    list_column.kind = ListColumn::ColumnKinds.first
    assert list_column.valid?
  end
               
  def test_list
    assert_equal lists(:list1), list_columns(:list1_column1).list
  end
  
  def test_list_cells
    assert_equal list_cells(:list1_row1_col1), list_columns(:list1_column1).list_cells.first
  end
  
  def test_list_cells_are_dependent
    assert list_cells(:list1_row1_col1).reload
    
    list_columns(:list1_column1).destroy
    
    assert_raise(ActiveRecord::RecordNotFound){ list_cells(:list1_row1_col1).reload }
  end
  
  def test_acts_as_list                                                               
    assert_equal 1, list_columns(:list1_column1).position
    assert_equal list_columns(:list1_column1), lists(:list1).list_columns.reload.first
    
    list_columns(:list1_column1).move_to_bottom
    
    assert_equal list_columns(:list1_column2), lists(:list1).list_columns.reload.first
    assert_equal list_columns(:list1_column1), lists(:list1).list_columns.reload.last 
    assert_equal lists(:list1).list_columns.size, list_columns(:list1_column1).position
  end
  
  def test_list_saved_after_save
    pre_time = lists(:list1).reload.updated_at
    
    list_columns(:list1_column1).save

    assert lists(:list1).reload.updated_at > pre_time
  end
  
  def test_cells_created_after_save
    cells_per_row = lists(:list1).list_rows.first.list_cells.reload.size
    
    lists(:list1).list_columns.create(:name => "tester", :kind => ListColumn::ColumnKinds.last)
                                                                                               
    assert_equal cells_per_row + 1, lists(:list1).list_rows.first.list_cells.reload.size
  end
  
  def test_list_saved_after_destroy
    pre_time = lists(:list1).reload.updated_at
    
    list_columns(:list1_column1).destroy

    assert lists(:list1).reload.updated_at > pre_time    
  end
            
  def test_create_cells
    orig_count = list_rows(:list1_root1).list_cells.reload.size
    
    list_rows(:list1_root1).list_cells.first.destroy
    
    # Confirm missing cell
    assert_equal orig_count - 1, list_rows(:list1_root1).list_cells.reload.size
    
    list_columns(:list1_column1).create_cells
    
    # Missing cell is added back, and there is no affect of calling this twice
    assert_equal orig_count, list_rows(:list1_root1).list_cells.reload.size
    assert_equal orig_count, list_rows(:list1_root1).list_cells.reload.size
  end
  
  def test_change_kind_to_same
    list_columns(:list1_column1).kind = list_columns(:list1_column1).kind
    
    assert_equal list_columns(:list1_column1).kind, list_columns(:list1_column1).kind
  end                          
  
  def test_change_kind_to_invalid_kind
    list_columns(:list1_column1).kind = 'widget'
    
    assert_equal list_columns(:list1_column1).kind, list_columns(:list1_column1).kind
  end
  
  def test_change_kind_to_valid_kind
    pre_time = lists(:list1).reload.updated_at
    checked  = list_columns(:list1_column1).list_cells.first.value

    list_columns(:list1_column1).kind = 'Number'
    
    assert_equal 'Number', list_columns(:list1_column1).kind
    assert_equal (checked == 'true' ? '1' : '0'), list_columns(:list1_column1).list_cells.first.value
    
    # Save was not called on the list
    assert_equal pre_time, lists(:list1).reload.updated_at
  end                                                       
  
  def test_change_kind_saves_cascade
    pre_time = lists(:list1).reload.updated_at
    checked  = list_columns(:list1_column1).list_cells.first.value

    list_columns(:list1_column1).update_attributes(:kind => 'Number')
    
    assert_equal 'Number', list_columns(:list1_column1).reload.kind
    assert_equal (checked == 'true' ? '1' : '0'), list_columns(:list1_column1).list_cells.first.reload.value
    
    # Save was called on the list
    assert lists(:list1).reload.updated_at > pre_time
  end
end