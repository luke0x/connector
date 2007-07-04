=begin #(fold)
Copyright 2004-2007 Joyent Inc.

Redistribution and/or modification of this code is governed
by either the GPLv2 or Joyent Commercial Software licenses.

Report issues and contribute at http://dev.joyent.com/

$Id$
=end #(end)

module JoyentRuby
  module Array
    
    def self.included(base)
      base.extend ClassMethods
    end
    
    # [1].index_by { |x| x.to_s } => {'1' => 1}
    def index_by
      inject({}) do |hsh, elt| 
        hsh[yield(elt)] = elt
        hsh
      end
    end
    
    # XXX Remove this with Rails 1.1 as a similar function is in ActiveSupport
    # return a hash mapping { block_result => [elements] }
    def group_by
      inject({}) do |hsh, elt|
        (hsh[yield(elt)] ||= []) << elt
        hsh
      end
    end

    # Rails version of this is broken, monkeypatch here until we update
    def groups_of(number)
      require 'enumerator' 
      collection = dup
      grouped_collection = [] unless block_given?
      collection.each_slice(number) do |group|
        block_given? ? yield(group) : grouped_collection << group
      end
      grouped_collection unless block_given?
    end

    # Apply block to each element of the receiver.  Each iteration of
    # the block should yield a two-element array.  Collect all the
    # returned two-element arrays as key-value pairs of a Hash.
    def hash_collect
      inject({}) do |hsh, elt|
        hsh.store(*(yield(elt)))
        hsh
      end
    end

    # for an array of hashes, return if any of the hashes has an element with the value
    # all of the elements must be a hash
    def contains_hash_with_value?(value)
      any? { |elt| elt.is_a?(Hash) && elt.has_value?(value) }
    end

    # returns the index of an object whose specified property matches the value
    # ex: [ Person.new('Adam'), Person.new('Bob') ].index_of_object_with_matching_property('name', 'Bob')
    #     would return 1
    def index_of_object_with_matching_property(property, value)
      each_with_index do |item, index|
        return index if item.send(property) == value
      end
      nil
    end

    module ClassMethods
      # sort array 1 by its default order and array 2 by the order that array 1 is sorted by
      def sort_in_parallel(arr1, arr2)
        raise "Arrays must be of equal length" unless arr1.length == arr2.length
        sorted = arr1.zip(arr2).sort{|a,b| a[0] <=> b[0]}.transpose
        (sorted == []) ? [[], []] : sorted
      end
    end

  end
end
