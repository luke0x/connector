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
  
  # instance methods
  
  def test_convert_to!
  end

  def test_create_cells
  end

  def test_validate
  end

end