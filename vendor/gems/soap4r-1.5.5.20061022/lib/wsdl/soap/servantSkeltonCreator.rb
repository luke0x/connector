# WSDL4R - Creating servant skelton code from WSDL.
# Copyright (C) 2002, 2003, 2005, 2006  NAKAMURA, Hiroshi <nahi@ruby-lang.org>.

# This program is copyrighted free software by NAKAMURA, Hiroshi.  You can
# redistribute it and/or modify it under the same terms of Ruby's license;
# either the dual license version in 2003, or any later version.


require 'wsdl/info'
require 'wsdl/soap/classDefCreatorSupport'
require 'xsd/codegen'


module WSDL
module SOAP


class ServantSkeltonCreator
  include ClassDefCreatorSupport
  include XSD::CodeGen::GenSupport

  attr_reader :definitions

  def initialize(definitions, modulepath = nil)
    @definitions = definitions
    @modulepath = modulepath
  end

  def dump(porttype = nil)
    result = ""
    if @modulepath
      result << "\n"
      result << @modulepath.collect { |ele| "module #{ele}" }.join("; ")
      result << "\n\n"
    end
    if porttype.nil?
      @definitions.porttypes.each do |type|
	result << dump_porttype(type.name)
	result << "\n"
      end
    else
      result << dump_porttype(porttype)
    end
    if @modulepath
      result << "\n\n"
      result << @modulepath.collect { |ele| "end" }.join("; ")
      result << "\n"
    end
    result
  end

private

  def dump_porttype(name)
    class_name = create_class_name(name)
    c = XSD::CodeGen::ClassDef.new(class_name)
    operations = @definitions.porttype(name).operations
    operations.each do |operation|
      name = safemethodname(operation.name)
      input = operation.input
      params = input.find_message.parts.collect { |part|
        safevarname(part.name)
      }
      m = XSD::CodeGen::MethodDef.new(name, params) do <<-EOD
            p [#{params.join(", ")}]
            raise NotImplementedError.new
          EOD
        end
      m.comment = dump_method_signature(operation)
      c.add_method(m)
    end
    c.dump
  end
end


end
end
