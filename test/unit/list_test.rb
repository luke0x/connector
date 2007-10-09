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

class ListTest < Test::Unit::TestCase
  fixtures all_fixtures
  include CRUDTest

  crud_data 'organization_id'           => 1,
            'user_id'                   => 1,
            'list_folder_id'            => 1,
            'name'                      => 'A List'
            
  crud_required 'organization_id', 'user_id', 'list_folder_id', 'name'
  
  def setup
    User.current = users(:ian)  
    
    @nested_opml = <<EOS
    <?xml version="1.0" encoding="UTF-8"?>
    <opml version="1.0">
      <head>
        <title>simple nested list</title>
        <expansionState>0,2,4</expansionState>
      </head>
      <body>
        <outline text="first stuff">
          <outline text="sub stuff"/>
          <outline text="another sub of stuff">
            <outline text="sub of sub stuff"/>
          </outline>
        </outline>
        <outline text="second stuff">
          <outline text="sub to second stuff"/>
        </outline>
        <outline text="third stuff"/>
      </body>
    </opml>    
EOS
  end
  
  # class methods

  def test_self_class_humanize
    assert_equal 'List', List.class_humanize
  end
  
  # def test_new_from_opml
  #   list = List.new_from_opml(@nested_opml)
  #   assert list.is_a?(List)
  #   assert list.has_list_columns?
  #   assert list.has_list_rows?
  #   assert_not_nil list.list_folder
  #   assert_equal ["text"], list.list_columns.map(&:name)
  #   assert_equal 7, list.list_rows.size
  #   assert_equal 7, list.list_rows.collect{|row| row.list_cells.map(&:value)}.flatten.size
  #   expected_values = [ "first stuff", "sub stuff", "another sub of stuff", "sub of sub stuff",
  #                       "second stuff", "sub to second stuff", "third stuff" ]
  #   assert_equal expected_values, list.list_rows.collect{|row| row.list_cells.collect(&:value) }.flatten
  #   assert_equal 1, list.list_rows.first.list_cells.size
  #   assert_equal "first stuff", list.list_rows.first.list_cells.first.value
  #   
  #   assert list.valid?
  # end

  def test_parse_opml
    parsed = List.parse_opml(@nested_opml)
    assert parsed.is_a?(Hash)
    assert parsed[:title].is_a?(String)
    assert parsed[:outlines].is_a?(Array)
    assert_equal "simple nested list", parsed[:title]
    assert_equal 3, parsed[:outlines].size
    assert_equal [], parsed[:outlines].last[:children]
    assert_equal 2, parsed[:outlines].first[:children].size
    assert_equal "sub stuff", parsed[:outlines].first[:children].first["text"]
    assert_equal 1, parsed[:outlines].first[:children].last[:children].size
  end
  
  def test_parse_outline
  end
  
  def test_search_fields
    assert List.search_fields.is_a?(Array)
    assert List.search_fields.length > 0
  end
  
  # instance methods
  
  def test_build_children
  end
  
  def test_build_outline
  end
  
  def test_class_humanize
    assert_equal 'List', List.class_humanize
  end
  
  def test_collapse!
    assert lists(:list1).list_rows.any?{|lr| lr.expanded?}
    lists(:list1).collapse!
    assert lists(:list1).list_rows.all?{|lr| lr.collapsed?}
  end
  
  # TODO: need correct fixtures for copy tests

  def test_copy
  end

  # def test_copy_to!
  #   lc = List.count
  #   lf = lists(:list1).list_folder
  #   assert_not_equal lists(:list1).list_folder, list_folders(:ian_lists)
  #   lists(:list1).copy_to!(list_folders(:ian_silly_lists))
  # 
  #   assert_equal lc, List.count
  #   assert_not_equal lists(:list1), lf
  # end
  
  def test_create_column_and_row
    l = lists(:list1)
    l.list_rows.clear
    l.list_columns.clear
    l.send(:create_column_and_row)
    l.reload
    
    assert_equal 1, l.list_rows.length
    assert_equal 1, l.list_columns.length
    assert_equal 1, l.list_rows.first.position
    assert_equal 'Text', l.list_columns.first.name
    assert_equal 'Text', l.list_columns.first.kind
  end
  
  def test_create_column_and_row_on_create
    l = List.new(:name => 'awesometown',
                 :user_id => User.current.id,
                 :organization_id => User.current.organization.id,
                 :list_folder_id => User.current.list_folders.first.id)
    assert_equal 0, l.list_rows.length
    assert_equal 0, l.list_columns.length
    assert l.save
    l.reload

    assert_equal 1, l.list_rows.length
    assert_equal 1, l.list_columns.length
    assert_equal 1, l.list_rows.first.position
    assert_equal 'Text', l.list_columns.first.name
    assert_equal 'Text', l.list_columns.first.kind
  end
  
  def test_create_row
  end
  
  def test_depth
  end
  
  def test_expand!
    assert lists(:list1).list_rows.any?{|lr| lr.collapsed?}
    lists(:list1).expand!
    assert lists(:list1).list_rows.all?{|lr| lr.expanded?}
  end
  
  def test_list_columns_by_position
  end
  
  def test_list_columns_for_search
    list = lists(:list1)
    assert_equal ":Done?::Completed::A Number::notes:", list.send(:list_columns_for_search)
  end
  
  def test_list_rows_for_search
    list = lists(:list1)
    cols = ListColumn.find_all_by_list_id(list.id)
    values = ListCell.find_all_by_list_column_id(cols.map(&:id))
    assert_equal ":#{values.map(&:value).join("::")}:", list.send(:list_rows_for_search)
  end
  
  def test_move_to!
    lc = List.count
    lf = lists(:list1).list_folder
    assert_not_equal lists(:list1).list_folder, list_folders(:ian_lists)
    lists(:list1).move_to!(list_folders(:ian_silly_lists))

    assert_equal lc, List.count
    assert_not_equal lists(:list1), lf
  end
  
  def test_opml_cell_value
  end
  
  def test_roots
  end
  
  def test_to_ascii
  end
  
  # def test_to_opml
  #   list = lists(:list1)
  #   opml = list.to_opml
  #   assert opml.include?("<title>#{list.name}</title>")
  #   assert opml.include?("<ownerName>Ian Kevin Curtis</ownerName>")
  #   assert opml.include?(%{notes="God I hate typing out fixtures"})
  #   assert opml.include?(%{<outline text=""/>})
  # end
  
end