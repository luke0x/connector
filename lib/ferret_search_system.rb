=begin #(fold)
Copyright 2004-2007 Joyent Inc.

Redistribution and/or modification of this code is governed
by either the GPLv2 or Joyent Commercial Software licenses.

Report issues and contribute at http://dev.joyent.com/

$Id$
=end #(end)

require 'ferret'

#######
# Warning, this system will eat your children if you use it
# This is more a proof of concept at present, so we can test the relative merits
# of HE vs Ferret when searching
# 
# Sadly Ferret appears to well, crash a lot.  Plus the deployment architecture is a little
# more complicated than HE's nice HTTP interface.
# 
# Still,  doesn't hurt,  plus it's pretty damned cool that we can just plug it in. 
# If you want to try it out, you can put the following into override_config.rb in RAILS_ROOT:
# Searchable.search_system = FerretSearchSystem.new("/some/directory/which/exists")
# Then run script/reindexer
#######
class FerretSearchSystem
  include Ferret::Document
  include Ferret::Search
  include Ferret::Index
  
  UNTOKENIZED_KEYS = ["@uri", "restricted_to", "orgid", "tagged_with"]
  
  def initialize(idx_path)
    @index = Index.new(:path => idx_path)
  end
  
  def add_item(i)
    doc = Document.new

    i.search_attributes.each do |k,v|
      next unless v
      if UNTOKENIZED_KEYS.index k
        doc << Field.new(k, v, Field::Store::YES, Field::Index::UNTOKENIZED)
      else
        doc << Field.new(k, v, Field::Store::YES, Field::Index::TOKENIZED)
      end
    end
    doc << Field.new("@body", i.search_text, Field::Store::YES, Field::Index::TOKENIZED)
    @index << doc
  end
  
  def smart_group(sg, limit=nil, offset=nil)
    search(::Query.from_smart_group(sg), limit, offset)
  end
  
  def text_query(text, type=nil)
    search(::Query.query_for(text, type))
  end
  
  def remove_item(i)
    @index.delete("#{i.class}:#{i.id}")
  end
  
  private
  
  def search(query, limit, offset)
    q = BooleanQuery.new
#    q = ""
    # orgid =
    # restricted_to
    # tags
    
    # full
    
    query.attributes.each do |k, v|
      q.add_query TermQuery.new(Term.new(k, v))
      #q << "#{k}: (#{v}) "
    end
    
    unless query.search_text.blank?
      q.add_query TermQuery.new(Term.new("body", query.search_text))
    end
    
    q.add_query TermQuery.new(Term.new("orgid", Organization.current.id.to_s))
    
    q.add_query TermQuery.new(Term.new("restricted_to", ":#{User.current.id}:"))
    
    unless query.tags.blank?
      q.add_query WildCardQuery.new(Term.new("tagged_with", tags_query(query.tags) ))
    end
    
    ds = []

    hits = @index.search(q)
    hits.each do |docnum, score|
      ds << docnum
    end
    
    uris = ds.collect{|dn| @index[dn]["@uri"]}
    h = uris.group_by {|r| type_for_url(r)}
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
  
  def tags_query(q)
    q.tags.sort.collect{|t| ":%:#{t}:%:" }.join("+*+")
  end
end