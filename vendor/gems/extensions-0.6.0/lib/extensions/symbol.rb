#!/usr/local/bin/ruby -w
#
# == extensions/symbol.rb
#
# Adds methods to the builtin Symbol class. 
#

require "extensions/_base"


#
# * Symbol#to_proc
#
ExtensionsProject.implement(Symbol, :to_proc) do
  class Symbol
    #
    # Allows a Symbol to be implicitly converted to a Proc.
    #
    # This allows such conveniences as:
    #   %{john terry fiona}.map(&:capitalize)   # -> %{John Terry Fiona}
    #   sum = numbers.inject(&:+)
    #
    def to_proc
      proc { |obj, *args| obj.send(self, *args) }
    end
  end
end

