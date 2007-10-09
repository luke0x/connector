=begin #(fold)
++
Copyright 2004-2007 Joyent Inc.

Redistribution and/or modification of this code is 
governed by the GPLv2.

Report issues and contribute at http://dev.joyent.com/

$Id$
--
=end #(end)


module JoyentRuby
  module Hash
    
    # Analogue of Array#compact; return a new Hash without the key/value pairs that have value=nil.
    def compact
      inject({}) do |hsh, elt|
        hsh.store(*elt) unless elt.last.nil?
        hsh
      end
    end

    # for a hash of hashes, return if any of the hashes has an element with the value all of the elements must be a hash
    def contains_hash_with_value?(value)
      values.any? { |elt| elt.is_a?(Hash) && elt.has_value?(value) }
    end

    # returns a copy of the hash, limited to keys that are in the specified array
    def limit_keys_to(keys)
      reject{|key,value| !keys.include?(key)}
    end

    # convert {1=>"a", 2=>"b", 3=>"b"} to {"a"=>[1], "b"=>[2, 3]}
    def flip
      new_hash = {}
      self.each do |key, value|
        new_hash[value] ||= []
        new_hash[value] << key
      end
      new_hash
    end
    
  end
end
