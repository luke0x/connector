=begin #(fold)
Copyright 2004-2007 Joyent Inc.

Redistribution and/or modification of this code is governed
by either the GPLv2 or Joyent Commercial Software licenses.

Report issues and contribute at http://dev.joyent.com/

$Id$
=end #(end)

class ListRow < ActiveRecord::Base
  include JoyentTree

  belongs_to :list
  has_many   :list_cells, :dependent => :destroy

  validates_presence_of :list_id
  validates_presence_of :position
  validates_presence_of :depth_cache

  acts_as_joyent_tree :order => 'position', :scope => :list_id

#  before_save :set_cache
  after_save {|record| record.list.save}
  after_save :create_cells
  before_destroy :destroy_children
  after_destroy {|record| record.list.save}

  def summary
    list.list_columns_by_position.collect{|list_column|
      ListCell.find_by_row_and_column(self, list_column).value
    }.compact.join(' : ')
  end
  
  def indent!
    return false unless self.previous_sibling

    ListRow.transaction do
      list.list_rows.find(:all, :lock => true)

      self.update_attributes(:parent_id => previous_sibling.id,
                             :position => (previous_sibling.children.blank? ? 1 : ListRow.maximum(:position, :conditions => ['list_id = ? AND parent_id = ?', previous_sibling.list_id, previous_sibling.id]) + 1),
                             :depth_cache => self.depth_cache + 1)

      children.each do |lr|
        lr.increment!(:depth_cache)
      end

      ancestors.each do |lr|
        lr.expand!
      end
    end
  end
  
  def outdent!
    return false if parent.blank?

    ListRow.transaction do
      list.list_rows.find(:all, :lock => true)

      # move the row's next siblings to after it's children
      last_child_pos = children.blank? ? 0 : children.last.position
      next_siblings.each_with_index do |lr, i|
        lr.update_attributes(:parent_id => self.id, :position => last_child_pos + i + 1)
      end

      # move the parent's next siblings down one to make room for the row
      parent.next_siblings.each do |lr|
        lr.increment!(:position)
      end

      # move the row out one to be the parent's next sibling
      self.update_attributes(:parent_id => parent.parent_id,
                             :position => parent.position + 1,
                             :depth_cache => self.depth_cache - 1)

      # move the row's descendents out one
      children.each do |lr|
        lr.move_out!
      end
    end
  end
  
  # move the depth out 1
  def move_out!
    self.decrement!(:depth_cache)
    children.map(&:move_out!)
  end
  
  def up!
    return false if previous_siblings.blank?
    
    ListRow.transaction do
      ps = previous_sibling
      ps.lock!
      self.lock!
      ps.update_attribute(:position, self.position)
      self.decrement!(:position)
    end
  end
  
  def down!
    return false if next_siblings.blank?

    ListRow.transaction do
      ns = next_sibling
      ns.lock!
      self.lock!
      ns.update_attribute(:position, self.position)
      self.increment!(:position)
    end
  end
  
  def expand!
    update_attributes :visible_children => true
  end
  
  def collapse!
    update_attributes :visible_children => false
  end
  
  def expanded?
    visible_children?
  end
  
  def collapsed?
    ! visible_children?
  end
  
  def visible?
    parent.blank? or ancestors.all?{|a| a.expanded?}
  end
  
  # fill-in cells for new rows
  def create_cells
    if List.current
      List.current.list_columns.each do |list_column|
        if list_cells.detect{|list_cell| list_cell.list_column_id == list_column.id}
          next
        else
          list_cells.create(:list_column_id => list_column.id)
        end
      end
    else
      list.list_columns.each do |list_column|
        if list_cells.detect{|list_cell| list_cell.list_column_id == list_column.id}
          next
        else
          list_cells.create(:list_column_id => list_column.id)
        end
      end
    end
  end
  
  def destroy_children
    children.map(&:destroy)
  end

  # joyent tree overrides
  
  def parent
    if List.current
      return nil if parent_id.blank?
      List.current.list_rows.detect{|lr| lr.id == self.parent_id}
    else
      return nil if parent_id.blank?
      @_parent ||= self.class.find(:first, :conditions => ["id = ? AND list_id = ?", self.parent_id, self.list_id], :order => 'position')
    end
  end
  
  def roots
    if List.current
      List.current.list_rows.select{|lr| lr.parent.blank?}.sort_by(&:position)
    else
      @_roots = self.class.find(:all, :conditions => ["parent_id IS NULL AND list_id = ?", self.list_id], :order => 'position')
    end
  end
  
  def children
    if List.current
      List.current.list_rows.select{|lr| lr.parent_id == self.id}.sort_by(&:position)
    else
      @_children ||= self.class.find(:all, :conditions => ["parent_id = ? AND list_id = ?", self.id, self.list_id], :order => 'position')
    end
  end
  
  # TODO: implement this + replace some uses of ListCell.find_by_row_and_column
  # def self.list_cells_in_order

  private

    # def set_cache
    #   return unless self.depth_cache.blank?
    #   
    #   self.depth_cache = if self.valid?
    #     self.depth
    #   else
    #     self.parent_id.blank? ? 0 : (self.parent.depth_cache + 1)
    #   end
    # end
  
end