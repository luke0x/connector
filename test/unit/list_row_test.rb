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
  
  crud_data 'list_id' => 1, 'depth_cache' => 1, 'position' => 2
  crud_required 'list_id', 'depth_cache', 'position'
  
  def setup
    User.current = users(:ian)  
  end
  
  def test_collapse!
    assert list_rows(:expanded).visible_children
    list_rows(:expanded).collapse!
    assert ! list_rows(:expanded).visible_children

    assert ! list_rows(:collapsed).visible_children
    list_rows(:collapsed).collapse!
    assert ! list_rows(:collapsed).visible_children
  end

  def test_collapsed?
    assert_not_equal list_rows(:collapsed).visible_children, list_rows(:collapsed).collapsed?
    assert_not_equal list_rows(:expanded).visible_children, list_rows(:expanded).collapsed?
  end

  def test_create_cells
  end

  def test_destroy_children
  end

  def test_down!
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

  def test_indent!
  end

  def test_move_out!
  end

  def test_outdent!
  end

  def test_summary
  end

  def test_up!
  end

  def test_visible?
  end

end