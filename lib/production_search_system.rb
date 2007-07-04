=begin #(fold)
Copyright 2004-2007 Joyent Inc.

Redistribution and/or modification of this code is governed
by either the GPLv2 or Joyent Commercial Software licenses.

Report issues and contribute at http://dev.joyent.com/

$Id$
=end #(end)

require "estraierpure"

class ProductionSearchSystem
  attr_accessor :factory, :uri, :user, :pass
  
  def initialize(uri, user, pass)
    @uri = uri
    @user = user
    @pass = pass
    @factory = Factory.new(self)
  end
  
  def smart_group(sg, limit=nil, offset=nil)
    search(Query.from_smart_group(sg), limit, offset)
  end
  
  def text_query(text, type=nil)
    search(Query.query_for(text, type))
  end
  
  def remove_item(i)
    node.out_doc_by_uri("#{i.class}:#{i.id}")
  end
  
  def add_item(i)
    sdoc = @factory.create_document

    i.search_attributes.each do |k,v|
      next unless v
      if !["@uri", "tagged_with"].index(k)
        v = v.downcase
      end
      sdoc.add_attr(k, v) 
    end
    
    sdoc.add_text(i.search_text)
    
    unless node.put_doc(sdoc)
      raise "Unable to add #{error_text(i)} to HyperEstraier, it said: #{@node.inspect}"
    end
  end
  
  def error_text(i)
    m = "#{i.class}:#{i.id}"
    if i.respond_to? :uid
      m << ":#{i.uid}"
    end
    m
  end
  
  def node
    @node ||= @factory.create_node
  end
  
  class Factory
    include EstraierPure
    
    def initialize(sys)
      @s = sys
    end
    
    def create_condition
      Condition::new
    end
  
    def create_document
      Document::new
    end
  
    def create_node
      @node = Node::new
      @node.set_url(@s.uri)
      @node.set_auth(@s.user, @s.pass)
      @node
    end
  end
  #######
  private
  #######
  
  def search(query, limit=nil, offset=nil)
    # if query.any?
    #   raise "Scott man, fix this"
    # end

    # create a search condition object
    cond = @factory.create_condition

    # set the search phrase to the search condition object
    cond.set_phrase(hax_stem(query.search_text))
    
    query.attributes.each do |k, v|
      cond.add_attr( "#{k} STRINC #{v.to_s.downcase}" )
    end
    
    cond.add_attr("orgid NUMEQ #{Organization.current.id}")
    
    if !query.tags.blank?
      cond.add_attr(tags_attr(query))
    end
    
    cond.add_attr(restriction_attr)
    
    # cond.set_max(limit) if limit
    # cond.set_skip(offset) if offset
    
    res = []
    # get the result of search
    nres = node.search(cond, 0);
    if nres
      # for each document in the result
      for i in 0...nres.doc_num
        # get a result document object
        rdoc = nres.get_doc(i)
        res  << rdoc.attr("@uri")
      end
      return find_all_for_uris(res, limit, offset)
    else
      return []
    end
  end
  
  def find_all_for_uris(results, limit=nil, offset=nil)
    h = results.group_by {|r| type_for_url(r)}
    h.inject([]) do |a, pair| 
      klazz = pair.first
      ids = pair.last.collect{|u| id_for_url(u)}
      # Seems hacky, but HE set_skip above seems to not be working.
      a.concat(klazz.find(:all, :conditions => ['id IN (?)', ids.sort.uniq], :limit => limit, :offset => offset))
      a
    end
  end
  
  def id_for_url(u)
    u.split(":").last.to_i
  end
  
  def type_for_url(u)
    Object.const_get(u.split(":").first)
  end
  
  def tags_attr(q)
    tags = q.tags.sort.collect{|t| ":%:#{t}:%:" }.join(".*")
    
    "tagged_with STRRX #{tags}"
  end
  
  def restriction_attr
    "restricted_to STRRX (^.*:#{User.current.id}:.*$)|^$"
  end
  
  def hax_stem(q)
    return nil unless q
    q.split.collect{|s| "[RX] .*#{s}.*"} * ' OR '
  end
end