=begin #(fold)
Copyright 2004-2007 Joyent Inc.

Redistribution and/or modification of this code is governed
by either the GPLv2 or Joyent Commercial Software licenses.

Report issues and contribute at http://dev.joyent.com/

$Id$
=end #(end)

require 'rexml/document'

class List < ActiveRecord::Base
  include JoyentItem

  belongs_to :list_folder
  has_many   :list_rows, :order => 'list_rows.position', :dependent => :destroy
  has_many   :list_columns, :order => 'list_columns.position', :dependent => :destroy

  validates_presence_of :list_folder_id
  validates_presence_of :name

  after_create :create_column_and_row

  cattr_accessor :current
  
  # localization
  untranslate_all 

  def self.class_humanize; 'List'; end
  def class_humanize; 'List'; end
  
  def self.new_from_opml(opml, list_folder_id=nil)
    expanded = expanded_outlines(opml)
    opml = parse_opml(opml)
    cols = map_columns(opml[:outlines]).uniq!
    group = list_folder_id || User.current.list_folders.find(:first).id
    
    transaction do
      list = List.create!(:name => opml[:title], :list_folder_id => group, :owner => User.current, :organization => Organization.current)
      list.list_rows.clear
      list.list_columns.clear
      
      # create the columns
      col_map = {} # name => ListColumn
      cols.each do |c|
        col_map[c] = list.list_columns.build(:name => c, :kind => "Text")
      end
      
      list.save!
      # Go over the outlines and create rows+values recursively as we go
      list.build_outline(opml[:outlines], col_map)
      list.list_rows.each_with_index do |row, i|
        row.update_attribute(:visible_children, true) if expanded.include?(i.to_s)
      end
      list.save!
    end
  end
  
  def build_outline(outlines, column_map, p_id=nil, depth=0)
    outlines.each_with_index do |outline, i|
      cell = 0
      row = list_rows.create(:position => i, :depth_cache => depth, :visible_children => false)
      outline.each do |column, value|
        if column == :children
          depth += 1
          build_outline(value, column_map, row.id, depth)
          depth += -1
        else
          # this will create an empty column for every row if there is a column like _note in arbitrary outlines or child outlines
          if column_map[column]
            row.update_attribute(:parent_id, p_id)
            row.list_cells[cell].update_attributes!(:value => value, :list_column_id => column_map[column].id)
            cell += 1
          end
        end
      end
    end
  end
  
  # because #inspect is annoying (don't trust sorting displayed by this)
  def to_ascii
    out = [(["row_id"] + list_columns_by_position.map(&:name)).join(" | ")]
    list_rows.each do |row|
      out << [([row.id] + row.list_cells.map{|v| v.value }).join(" | ")]
    end
    out.join("\n")
  end
  
  def self.parse_opml(opml)
    doc = REXML::Document.new(opml)
    title = doc.elements["opml/head/title"].text
    outlines = []
    doc.elements.each("opml/body/outline") do |element|
      outlines << parse_outline(element)      
    end
    {:title => title, :outlines => outlines}
  end
  
  def self.expanded_outlines(opml)
    doc = REXML::Document.new(opml)
    expanded = doc.elements["opml/head/expansionState"].text.split(',')
  end
  
  def self.parse_outline(node, previous=[])
    outline = {}
    if node.elements != 0
      outline[:children] = node.elements.map{|e| parse_outline(e, previous + [outline])}
    end
    node.attributes.each do |k, v|
      outline[k] = v
    end
    outline
  end
  
  def to_opml
    x = Builder::XmlMarkup.new(:indent => 2)
    x.instruct!
    x.opml(:version => 1.0) do |o|
      o.head do |h|
        h.title self.name
        h.dateCreated self.created_at
    		h.dateModified self.updated_at
    		h.ownerName self.owner.person.full_name
    		h.ownerEmail self.owner.person.primary_email
        h.expansionState self.expansion_state
      end
      o.body do |b|
        self.roots.sort_by(&:position).each do |list_row|
          values = list_row.list_cells
          text = values.detect {|v| v && v.kind != 'Checkbox' }
          rest_values = values.inject({}) do |hsh, v| # Build attrib_without_space => value hash of the rest
            hsh[v.list_column.name.gsub(/\W+/, "").to_sym] = opml_cell_value(v) unless v == text
            hsh
          end
          b.outline({:text => text.value}.merge(rest_values)) do |oo|
            list_row.children.each do |child|
              build_children(child, oo)
            end
          end
        end
      end
    end
  end
  
  def expansion_state
    positions = []
    self.list_rows.each_with_index do |row, i|
      positions << i if row.visible_children?
    end
    positions.join(',')
  end
  
  def build_children(child, oo)
    child_values = child.list_cells
    child_text = child_values.detect {|v| v && v.kind != 'Checkbox' }
    child_rest_values = child_values.inject({}) do |hsh, v|
      hsh[v.list_column.name.gsub(/\W+/, "").to_sym] = opml_cell_value(v) unless v == child_text
      hsh
    end
    oo.outline({:text => child_text.value}.merge(child_rest_values)) do |co|
      child.children.each do |c|
        build_children(c, oo)
      end
    end
  end
  
  def self.map_columns(outlines, ary=[])
    outlines.each do |outline|
      outline.each do |column, value|
        if column == :children
          map_columns(value, ary)
        else
          ary << column
        end
      end
    end
    ary
  end
  
  def opml_cell_value(list_cell)
    case list_cell.kind
    when 'Checkbox'
      list_cell.value == 'true' ? 1 : 0
    when 'Date', 'Number', 'Text'
      out = ''
      out << list_cell.value unless list_cell.value.nil?
    end
  end

  def self.search_fields
    [
      'users.username',
      'lists.name'
      # TODO: need to search list contents also
      # list_columns_for_search
      # list_rows_for_search
    ]
  end

  # deep clone + save
  def clone
    new_list = transaction do
      new_list = super
      new_list.save!
      new_list
    end
    transaction do
      new_list.list_rows.clear
      new_list.list_columns.clear
    
      # copy the columns
      column_map = {} # old => new
      list_columns.each do |column|
        new_column = column.clone
        new_column.list_id = new_list.id
        new_column.save!
        column_map[column.id] = new_column.id
      end

      # copy the rows
      row_map = {} # old => new
      list_rows.each do |row|
        new_row = row.clone
        new_row.list_id = new_list.id
        new_row.parent_id = nil
        new_row.save!
        row_map[row.id] = new_row.id
      end

      # reparent the rows now that the row_map is complete
      list_rows.each do |row|
        if row.parent_id
          new_row = new_list.list_rows.find(row_map[row.id])
          new_row.parent_id = row_map[row.parent_id]
          new_row.save!
        end
      end
      
      new_list.reload

      # missing cells automatically created when saving columns/rows
      # just go thru the new ones + set the values
      # NOTE: if the list_cell schema changes this may need to be updated
      column_map     = column_map.invert # new => old
      row_map        = row_map.invert    # new => old
      old_list_cells = list_cells
      new_list.list_cells.each do |new_list_cell|
        old_list_column_id = column_map[new_list_cell.list_column_id]
        if old_list_column_id.blank?
          raise 'old list col id blank'
        end
        old_list_row_id    = row_map[new_list_cell.list_row_id]
        raise 'old list row id blank' if old_list_row_id.blank?
        old_list_cell      = old_list_cells.detect{|lc| lc.list_row_id == old_list_row_id and lc.list_column_id == old_list_column_id}
        raise 'old list cell blank' if old_list_cell.blank?
        next unless old_list_cell # HAX: can't destroy that initial column yet
        new_list_cell.update_attributes!({ :value => old_list_cell.value })
      end

      # clone tags + permissions, skip comments + notifications
      taggings.each{|tagging| new_list.taggings << tagging.clone}
      permissions.each{|permission| new_list.permissions << permission.clone}

      new_list
    end # transaction
  end

  def move_to!(list_folder)
    return unless list_folder.is_a?(ListFolder)
    return unless User.current.can_move?(self)

    self.update_attribute(:list_folder_id, list_folder.id)
  end

  def copy_to!(list_folder)
    return unless list_folder.is_a?(ListFolder)
    return unless User.current.can_copy?(self)

    new_list = self.clone
    transaction do
      new_list.list_folder_id = list_folder.id
      new_list.user_id = User.current
      new_list.save!
    end # transaction
  end
  
  def expand!
    list_rows.map(&:expand!)
  end
  
  def collapse!
    list_rows.map(&:collapse!)
  end
  
  def create_row(selected_list_row = nil)
    ListRow.transaction do
      List.current.list_rows.find(:all, :lock => true)

      # create new root at end of list
      if selected_list_row.blank?
        pos = (List.current.roots.collect(&:position).max.to_i + 1) || 1
        List.current.list_rows.create(:parent_id => nil, :position => pos, :depth_cache => 0)
      else
        # create after row at same depth
        if selected_list_row.collapsed? or selected_list_row.leaf?
          # move all subsequent rows forward 1
          next_siblings = List.current.list_rows.select{|lr| lr.parent_id == selected_list_row.parent_id and lr.position > selected_list_row.position}
          next_siblings.each do |lr|
            lr.update_attribute(:position, lr.position + 1)
          end

          # create row at current position
          List.current.list_rows.create(:parent_id => selected_list_row.parent_id, :position => selected_list_row.position + 1, :depth_cache => selected_list_row.depth_cache)
        # create new first child
        else
          selected_list_row.children.each do |lr|
            lr.update_attribute(:position, lr.position + 1)
          end
          List.current.list_rows.create(:parent_id => selected_list_row.id, :position => 1, :depth_cache => selected_list_row.depth_cache + 1)
        end
      end
    end # transaction
  end
  
  def roots
    if List.current
      List.current.list_rows.blank? ? [] : List.current.list_rows.first.roots
    else
      list_rows.blank? ? [] : list_rows.first.roots
    end
  end
  
  def depth
    list_rows.collect(&:depth_cache).max.to_i
  end
  
  def list_columns_by_position
    if List.current
      @list_columns_by_position ||= List.current.list_columns.sort_by(&:position)
    else
      @list_columns_by_position ||= ListColumn.find(:all, :conditions => ["list_id = ?", self.id], :order => 'list_columns.position')
    end
  end
  
  def list_cells
    if List.current
      List.current.list_rows.collect{|row| row.list_cells}.flatten
    else
      list_rows(true).collect{|row| row.list_cells(true)}.flatten
    end
  end
  
  private
  
    def create_column_and_row
      self.list_columns.create!(:name => _('Text'), :kind => 'Text')
      self.list_rows.create!(:position => 1, :depth_cache => 0)
    end

    def list_columns_for_search
      list_columns_by_position.collect{|lc| ":#{lc.name}:"}.join
    end
      
    def list_rows_for_search
      list_rows.collect do |lr|
        lr.list_cells.collect do |lc|
          ":#{lc.value}:"
        end.join
      end.join
    end
    
end