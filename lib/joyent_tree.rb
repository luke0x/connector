=begin #(fold)
Copyright 2004-2007 Joyent Inc.

Redistribution and/or modification of this code is governed
by either the GPLv2 or Joyent Commercial Software licenses.

Report issues and contribute at http://dev.joyent.com/

$Id$
=end #(end)

module JoyentTree
  def self.included(base)
    base.extend(ClassMethods)
  end

  module ClassMethods
    def acts_as_joyent_tree(options = {})
      raise "Joyent tree requires scope" unless options.include?(:scope)
      raise "Joyent tree requires position attribute" unless column_names.include?('position')

      @@configuration = { :foreign_key => "parent_id", :order => nil, :counter_cache => nil }
      @@configuration.update(options) if options.is_a?(Hash)

      class_eval <<-EOV
        include JoyentTree::InstanceMethods
      EOV
    end
  end

  module InstanceMethods
    def parent
      return nil if parent_id.blank?
      @_parent ||= self.class.find(:first, :conditions => ["id = ? AND list_id = ?", self.parent_id, self.list_id], :order => 'position')
    end
    
    def parent_with_tree(tree_rows)
      tree_rows.detect{|t| t.id == parent_id}
    end
    
    def children
      @_children ||= self.class.find(:all, :conditions => ["parent_id = ? AND list_id = ?", self.id, self.list_id], :order => 'position')
    end
    
    def ancestors
      node, nodes = self, []
      nodes << node = node.parent while node.parent
      @_ancestors ||= nodes
    end
    
    def ancestors_with_tree(tree_rows)
      node, nodes = self, []
      while p = node.parent_with_tree(tree_rows)
        nodes << p
        node = p
      end
      nodes
    end

    # not in any particular order
    def descendents
      nodes = children.compact
      children.compact.each{|child| nodes << child.descendents}
      nodes.flatten
    end

    def root
      parent ? ancestors.last : self
    end

    def roots
      @_roots = self.class.find(:all, :conditions => ["parent_id IS NULL AND list_id = ?", self.list_id], :order => 'position')
    end

    def siblings
      self_and_siblings - [self]
    end

    def self_and_siblings
      parent ? parent.children : self.roots
    end

    def next_siblings
      siblings.select{|s| s.position > self.position}.sort_by(&:position)
    end
    
    def previous_siblings
      siblings.select{|s| s.position < self.position}.sort_by(&:position)
    end

    def next_sibling
      next_siblings ? next_siblings.first : nil
    end

    def previous_sibling
      previous_siblings ? previous_siblings.last : nil
    end
    
    def root?
      parent.blank?
    end
    
    def leaf?
      children.blank?
    end
    
    def depth(tree_rows=nil)
      @_depth ||= if tree_rows
        ancestors_with_tree(tree_rows).length
      else
        ancestors.length
      end
    end
  end
end