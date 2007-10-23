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

class ListRowTest < Test::Unit::TestCase
  fixtures all_fixtures
  include CRUDTest
  
  crud_data     'list_id'     => 1, 
                'depth_cache' => 1, 
                'position'    => 2
                
  crud_required 'list_id', 'depth_cache', 'position'
  
  def setup
    User.current = users(:ian)  
  end            
            
  def test_list
    assert_equal lists(:list1), list_rows(:list1_root1).list
  end
  
  def test_list_cells
    assert_equal list_cells(:list1_row1_col1), list_rows(:list1_root1).list_cells.first
  end
  
  def test_cells_dependent
    assert list_cells(:list1_row1_col1).reload
    
    list_rows(:list1_root1).destroy
    
    assert_raise(ActiveRecord::RecordNotFound){ list_cells(:list1_row1_col1).reload }
  end
               
  def test_joyent_tree
    # Lets just make sure this stays as a tree by testing a random method
    assert_equal list_rows(:list1_root1), list_rows(:list1_root1_child1).root
  end                                                                    
  
  def test_cells_created_after_save
    cells_per_row = lists(:list1).list_rows.first.list_cells.reload.size
    
    new_row = lists(:list1).list_rows.create(:depth_cache => 1, :position => 0)
                                                                                               
    assert_equal cells_per_row, new_row.reload.list_cells.size
  end
  
  def test_list_saved_after_save
    pre_time = lists(:list1).reload.updated_at
    
    list_rows(:list1_root1).save

    assert lists(:list1).reload.updated_at > pre_time
  end                                                                          
  
  def test_list_saved_after_destroy
    pre_time = lists(:list1).reload.updated_at
    
    list_rows(:list1_root1).destroy

    assert lists(:list1).reload.updated_at > pre_time    
  end
                                   
  def test_children_destroyed_after_destroy
    assert list_rows(:list1_root1_child1)
    assert list_rows(:list1_child1_child1)
    
    list_rows(:list1_root1).destroy
    
    assert_raise(ActiveRecord::RecordNotFound){ list_rows(:list1_root1_child1).reload }
    assert_raise(ActiveRecord::RecordNotFound){ list_rows(:list1_child1_child1).reload }    
  end
  
  def test_summary
    cells    = list_rows(:list1_root1).list_cells.sort_by{|lc| lc.list_column.position}
    expected = cells.collect(&:value).join(' : ')
    
    assert_equal expected, list_rows(:list1_root1).summary
  end
                                                   
  def test_indent_no_previous_sibling
    pre_depth = list_rows(:list1_root1_child1).reload.depth_cache
    pre_parent_id = list_rows(:list1_root1_child1).reload.parent_id
    
    assert       !list_rows(:list1_root1_child1).indent!    
    assert_equal pre_depth, list_rows(:list1_root1_child1).reload.depth_cache
    assert_equal pre_parent_id, list_rows(:list1_root1_child1).reload.parent_id
  end                                                                 
  
  def test_indent
    pre_depth = list_rows(:list1_root1_child2).reload.depth_cache
    
    assert_not_equal list_rows(:list1_root1_child1).id, list_rows(:list1_root1_child2).reload.parent_id
    assert_equal     pre_depth + 1, list_rows(:list1_child2_child1).reload.depth_cache
    
    assert           list_rows(:list1_root1_child2).indent!    
    
    assert_equal     pre_depth + 1, list_rows(:list1_root1_child2).reload.depth_cache    
    assert_equal     list_rows(:list1_root1_child1).id, list_rows(:list1_root1_child2).reload.parent_id
    assert_equal     pre_depth + 2, list_rows(:list1_child2_child1).reload.depth_cache
    
    list_rows(:list1_root1_child2).ancestors.each do |ancestor|
      assert ancestor.reload.visible_children
    end
  end
       
  def test_outdent_no_parent
    pre_depth = list_rows(:list1_root1).reload.depth_cache
    
    assert       !list_rows(:list1_root1).outdent!    
    assert_equal pre_depth, list_rows(:list1_root1).reload.depth_cache    
  end                                                                 
  
  def test_outdent
    assert           list_rows(:list1_root1_child1).reload.parent
    assert_equal     list_rows(:list1_root1).id, list_rows(:list1_root1_child2).reload.parent_id
    assert_equal     1, list_rows(:list1_root1_child1).reload.depth_cache
    assert_equal     2, list_rows(:list1_child1_child1).reload.depth_cache
    assert_equal     1, list_rows(:list1_root1_child2).reload.depth_cache    
    assert_equal     2, list_rows(:list1_root1_child2).reload.position
    assert_equal     2, list_rows(:list1_root2).reload.position
    
    assert           list_rows(:list1_root1_child1).outdent!

    assert           !list_rows(:list1_root1_child1).reload.parent
    assert_equal     list_rows(:list1_root1_child1).id, list_rows(:list1_root1_child2).reload.parent_id
    assert_equal     0, list_rows(:list1_root1_child1).reload.depth_cache 
    assert_equal     1, list_rows(:list1_child1_child1).reload.depth_cache
    assert_equal     1, list_rows(:list1_root1_child2).reload.depth_cache
    assert_equal     2, list_rows(:list1_root1_child1).reload.position
    assert_equal     3, list_rows(:list1_root2).reload.position
  end      
  
  def test_up
    assert       !list_rows(:list1_root1).up!
    
    assert_equal 1, list_rows(:list1_root1).reload.position
    assert_equal 2, list_rows(:list1_root2).reload.position 
    
    assert       list_rows(:list1_root2).up!
    
    assert_equal 2, list_rows(:list1_root1).reload.position
    assert_equal 1, list_rows(:list1_root2).reload.position 
  end
  
  def test_down
    assert       !list_rows(:list1_root2).down!
    
    assert_equal 1, list_rows(:list1_root1).reload.position
    assert_equal 2, list_rows(:list1_root2).reload.position 
    
    assert       list_rows(:list1_root1).down!
    
    assert_equal 2, list_rows(:list1_root1).reload.position
    assert_equal 1, list_rows(:list1_root2).reload.position    
  end
  
  def test_collapse!
    assert list_rows(:expanded).visible_children
    list_rows(:expanded).collapse!
    assert ! list_rows(:expanded).visible_children

    assert ! list_rows(:collapsed).visible_children
    list_rows(:collapsed).collapse!
    assert ! list_rows(:collapsed).visible_children
  end

  def test_expand!
    assert ! list_rows(:collapsed).visible_children
    list_rows(:collapsed).expand!
    assert list_rows(:collapsed).visible_children

    assert list_rows(:expanded).visible_children
    list_rows(:expanded).expand!
    assert list_rows(:expanded).visible_children
  end

  def test_expanded?
    assert_equal list_rows(:collapsed).visible_children, list_rows(:collapsed).expanded?
    assert_equal list_rows(:expanded).visible_children, list_rows(:expanded).expanded?
  end
    
  def test_collapsed?
    assert_not_equal list_rows(:collapsed).visible_children, list_rows(:collapsed).collapsed?
    assert_not_equal list_rows(:expanded).visible_children, list_rows(:expanded).collapsed?
  end

  def test_visible?
    assert list_rows(:list1_root1).visible?
    
    assert_equal list_rows(:list1_child1_child1).ancestors.all?(&:expanded?), list_rows(:list1_child1_child1).visible?
    
    list_rows(:list1_child1_child1).ancestors.each(&:expand!)                                                         
    
    assert list_rows(:list1_child1_child1).reload.visible?
   
    list_rows(:list1_child1_child1).ancestors.last.collapse!
    
    assert !list_rows(:list1_child1_child1).reload.visible?    
  end
  
  

end