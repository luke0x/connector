# SOAP4R - XML Literal EncodingStyle handler library
# Copyright (C) 2001, 2003-2005  NAKAMURA, Hiroshi <nahi@ruby-lang.org>.

# This program is copyrighted free software by NAKAMURA, Hiroshi.  You can
# redistribute it and/or modify it under the same terms of Ruby's license;
# either the dual license version in 2003, or any later version.


require 'soap/encodingstyle/handler'


module SOAP
module EncodingStyle


class LiteralHandler < Handler
  Namespace = SOAP::LiteralNamespace
  add_handler

  def initialize(charset = nil)
    super(charset)
    @textbuf = ''
  end


  ###
  ## encode interface.
  #
  def encode_data(generator, ns, data, parent)
    attrs = {}
    name = generator.encode_name(ns, data, attrs)
    data.extraattr.each do |key, value|
      next if !@generate_explicit_type and key == XSD::AttrTypeName
      # ToDo: check generator.attributeformdefault here
      if key.is_a?(XSD::QName)
        key = encode_qname(attrs, ns, key)
      end
      if value.is_a?(XSD::QName)
        value = encode_qname(attrs, ns, value)
      end
      attrs[key] = value
    end
    case data
    when SOAPRawString
      generator.encode_tag(name, attrs)
      generator.encode_rawstring(data.to_s)
    when XSD::XSDString
      generator.encode_tag(name, attrs)
      str = data.to_s
      str = XSD::Charset.encoding_to_xml(str, @charset) if @charset
      generator.encode_string(str)
    when XSD::XSDAnySimpleType
      generator.encode_tag(name, attrs)
      generator.encode_string(data.to_s)
    when SOAPStruct
      generator.encode_tag(name, attrs)
      data.each do |key, value|
        generator.encode_child(ns, value, data)
      end
    when SOAPArray
      generator.encode_tag(name, attrs)
      data.traverse do |child, *rank|
	data.position = nil
        generator.encode_child(ns, child, data)
      end
    when SOAPElement
      # passes 2 times for simplifying namespace definition
      data.each do |key, value|
        if value.elename.namespace
          SOAPGenerator.assign_ns(attrs, ns, value.elename.namespace)
        end
      end
      if data.text and data.text.is_a?(XSD::QName)
        SOAPGenerator.assign_ns(attrs, ns, data.text.namespace)
      end
      generator.encode_tag(name, attrs)
      if data.text
        if data.text.is_a?(XSD::QName)
          text = ns.name(data.text)
        else
          text = data.text
        end
        generator.encode_rawstring(text)
      end
      data.each do |key, value|
        generator.encode_child(ns, value, data)
      end
    else
      raise EncodingStyleError.new(
        "unknown object:#{data} in this encodingStyle")
    end
  end

  def encode_data_end(generator, ns, data, parent)
    name = generator.encode_name_end(ns, data)
    cr = (data.is_a?(SOAPCompoundtype) or
      (data.is_a?(SOAPElement) and !data.text))
    generator.encode_tag_end(name, cr)
  end


  ###
  ## decode interface.
  #
  class SOAPTemporalObject
    attr_accessor :parent

    def initialize
      @parent = nil
    end
  end

  class SOAPUnknown < SOAPTemporalObject
    def initialize(handler, elename, extraattr)
      super()
      @handler = handler
      @elename = elename
      @extraattr = extraattr
    end

    def as_element
      if @extraattr[XSD::AttrNilName] == 'true'
        return as_nil
      end
      o = SOAPElement.decode(@elename)
      o.parent = @parent
      o.extraattr.update(@extraattr)
      @handler.decode_parent(@parent, o)
      o
    end

    def as_string
      if @extraattr[XSD::AttrNilName] == 'true'
        return as_nil
      end
      o = SOAPString.decode(@elename)
      o.parent = @parent
      o.extraattr.update(@extraattr)
      @handler.decode_parent(@parent, o)
      o
    end

    def as_nil
      o = SOAPNil.decode(@elename)
      o.parent = @parent
      o.extraattr.update(@extraattr)
      @handler.decode_parent(@parent, o)
      o
    end
  end

  def decode_tag(ns, elename, attrs, parent)
    @textbuf = ''
    o = SOAPUnknown.new(self, elename, decode_attrs(ns, attrs))
    o.parent = parent
    o
  end

  def decode_tag_end(ns, node)
    o = node.node
    if o.is_a?(SOAPUnknown)
      if /\A\s*\z/ =~ @textbuf
        newnode = o.as_element
      else
        newnode = o.as_string
      end
      node.replace_node(newnode)
      o = node.node
    end

    decode_textbuf(o)
    @textbuf = ''
  end

  def decode_text(ns, text)
    # @textbuf is set at decode_tag_end.
    @textbuf << text
  end

  def decode_attrs(ns, attrs)
    extraattr = {}
    attrs.each do |key, value|
      qname = ns.parse_local(key)
      extraattr[qname] = value
    end
    extraattr
  end

  def decode_prologue
  end

  def decode_epilogue
  end

  def decode_parent(parent, node)
    return unless parent.node
    case parent.node
    when SOAPUnknown
      newparent = parent.node.as_element
      node.parent = newparent
      parent.replace_node(newparent)
      decode_parent(parent, node)
    when SOAPElement
      parent.node.add(node)
      node.parent = parent.node
    when SOAPStruct
      parent.node.add(node.elename.name, node)
      node.parent = parent.node
    when SOAPArray
      if node.position
	parent.node[*(decode_arypos(node.position))] = node
	parent.node.sparse = true
      else
	parent.node.add(node)
      end
      node.parent = parent.node
    else
      raise EncodingStyleError.new("illegal parent: #{parent.node}")
    end
  end

private

  def decode_textbuf(node)
    if node.is_a?(XSD::XSDString)
      if @charset
	node.set(XSD::Charset.encoding_from_xml(@textbuf, @charset))
      else
	node.set(@textbuf)
      end
    else
      # Nothing to do...
    end
  end
end

LiteralHandler.new


end
end
