=begin #(fold)
Copyright 2004-2007 Joyent Inc.

Redistribution and/or modification of this code is governed
by either the GPLv2 or Joyent Commercial Software licenses.

Report issues and contribute at http://dev.joyent.com/

$Id$
=end #(end)

# require File.dirname(__FILE__) + '/../test_helper'
# 
# require 'flexmock'
# 
# class TestSearchStuffFactory
#   attr_accessor :create_document, :create_node, :create_condition
# end
# 
# class ProductionSearchSystemTest < Test::Unit::TestCase
#   fixtures all_fixtures
#   include FlexMock::TestCase
#   
#   def setup
#     # none of the 'do stuff' methods will actually be called as we've monkeypatched
#     # them away
#     
#     @system = ProductionSearchSystem.new("http://foo", "foo", "bar")
#     @factory = TestSearchStuffFactory.new
#     @system.factory= @factory
#   end
#   
#   def test_add_item
#     @doc = flexmock("doc")
#     @doc.should_receive(:add_attr).times(10).with(String, String)
#     @doc.should_receive(:add_text).with(String)
#     @factory.create_document= @doc
#     
#     @node = flexmock("node")
#     @node.should_receive(:put_doc).with(@doc).and_return { true }
#     @factory.create_node= @node
# 
#     @system.add_item(people(:ian)) 
#   end
#   
#   def test_add_item_where_putdoc_fails
#     @doc = flexmock("doc")
#     @doc.should_receive(:add_attr).times(10).with(String, String)
#     @doc.should_receive(:add_text).with(String)
#     @factory.create_document= @doc
#     
#     @node = flexmock("node")
#     @node.should_receive(:put_doc).with(@doc).and_return { false }
#     @factory.create_node= @node
#     
#     assert_raise(RuntimeError) { @system.add_item(people(:ian)) }
#   end
#   
#   def test_remove_item
#     @node = flexmock("node")
#     @node.should_receive(:out_doc_by_uri).with("Person:1").and_return { true }
#     @factory.create_node=@node
#     
#     @system.remove_item(people(:ian))
#   end
#   
#   def test_remove_item_where_outdoc_fails
#     @node = flexmock("node")
#     @node.should_receive(:out_doc_by_uri).with("Person:1").and_return { false }
#     @factory.create_node=@node
#     
#     @system.remove_item(people(:ian))
#   end
#   
#   def test_text_query_no_options
#     User.current=users(:ian)
#     
#     @results = flexmock("results")
#     @results.should_receive(:doc_num).and_return { 0 }
#     
#     
#     @cond = flexmock("condition")
#     @cond.should_receive(:set_phrase).with("[RX] .*foo.*")
#     @cond.should_receive(:add_attr).with(String).times(2)
#     
#     @factory.create_condition=@cond
#     
#     
#     @node = flexmock("node")
#     @node.should_receive(:search).with(@cond, 0).and_return { @results }
#     
#     @factory.create_node=@node
#     
#     @system.text_query("foo")
#   end
#   
#   def test_text_query_no_options2
#     User.current=users(:ian)
#     
#     @results = flexmock("results")
#     @results.should_receive(:doc_num).and_return { 0 }
#     
#     
#     @cond = flexmock("condition")
#     @cond.should_receive(:set_phrase).with("[RX] .*foo.*")
#     @cond.should_receive(:add_attr).with("orgid NUMEQ 1")
#     @cond.should_receive(:add_attr).with("item_type STRINC person")
#     @cond.should_receive(:add_attr).with("restricted_to STRRX (^.*:1:.*$)|^$")
#     
#     @factory.create_condition=@cond
#     
#     
#     @node = flexmock("node")
#     @node.should_receive(:search).with(@cond, 0).and_return { @results }
#     
#     @factory.create_node=@node
#     
#     @system.text_query("foo", "Person")
#   end
#   
#   def test_smart_group_no_tags
#     User.current=users(:ian)
#     
#     @results = flexmock("results")
#     @results.should_receive(:doc_num).and_return { 0 }
#     
#     
#     @cond = flexmock("condition")
#     @cond.should_receive(:set_phrase).with("")
#     @cond.should_receive(:add_attr).with("orgid NUMEQ 1")
#     @cond.should_receive(:add_attr).with("item_type STRINC person")
#     @cond.should_receive(:add_attr).with("restricted_to STRRX (^.*:1:.*$)|^$")
#     @cond.should_receive(:add_attr).with("owner_name STRINC peter")
#     
#     @factory.create_condition=@cond
#     
#     
#     @node = flexmock("node")
#     @node.should_receive(:search).with(@cond, 0).and_return { @results }
#     
#     @factory.create_node=@node
#     
#     @system.smart_group(smart_groups(:ian_everything_from_peter))
#   end
# 
#   def test_smart_group_with_tags
#     User.current=users(:ian)
#     
#     @result = flexmock("result")
#     @result.should_receive(:attr).with("@uri").and_return { "Person:1" }
#     
#     @results = flexmock("results")
#     @results.should_receive(:doc_num).and_return { 1 }
#     @results.should_receive(:get_doc).with(0).and_return { @result }
#     
#     
#     @cond = flexmock("condition")
#     @cond.should_receive(:set_phrase).with("")
#     @cond.should_receive(:add_attr).with("orgid NUMEQ 1")
#     @cond.should_receive(:add_attr).with("item_type STRINC event")
#     @cond.should_receive(:add_attr).with("restricted_to STRRX (^.*:1:.*$)|^$")
#     @cond.should_receive(:add_attr).with("tagged_with STRRX :%:orange:%:.*:%:raspberry:%:")
#     
#     @factory.create_condition=@cond
#     
#     
#     @node = flexmock("node")
#     @node.should_receive(:search).with(@cond, 0).and_return { @results }
#     
#     @factory.create_node=@node
#     
#     assert_equal [people(:ian)], @system.smart_group(smart_groups(:ian_events_tagged_with_orange_and_raspberry))
#   end
# 
#   
#   def test_regression_for_3087
#     User.current=users(:ian)
#     
#     @result = flexmock("result")
#     @result.should_receive(:attr).with("@uri").and_return { "Person:1" }
#     
#     @results = flexmock("results")
#     @results.should_receive(:doc_num).and_return { 1 }
#     @results.should_receive(:get_doc).with(0).and_return { @result }
#     
#     
#     @cond = flexmock("condition")
#     @cond.should_receive(:set_phrase).with("")
#     @cond.should_receive(:add_attr).with("orgid NUMEQ 1")
#     @cond.should_receive(:add_attr).with("item_type STRINC joyentfile")
#     @cond.should_receive(:add_attr).with("restricted_to STRRX (^.*:1:.*$)|^$")
#     @cond.should_receive(:add_attr).with("tagged_with STRRX :%:Rails:%:.*:%:Solaris:%:")
#     
#     @factory.create_condition=@cond
#     
#     
#     @node = flexmock("node")
#     @node.should_receive(:search).with(@cond, 0).and_return { @results }
#     
#     @factory.create_node=@node
#     
#     assert_equal [people(:ian)], @system.smart_group(smart_groups(:ian_jason_regression))
#   end
#   
#   def test_add_item_regression_3087
#     @doc = flexmock("doc")
#     
#     @doc.should_ignore_missing
#     {
#     "tagged_with", ":%:Rails:%::%:Solaris:%:",
#     "restricted_to", "",
#     "company_name", "",
#     "owner_name", "ian",
#     "@uri", "Person:11",
#     "first_name", "rails",
#     "last_name", "solaris",
#     "full_name", "rails solaris",
#     "orgid", "1",
#     "item_type", "person"
#     }.each do |k,v|       
#       @doc.should_receive(:add_attr).with(k,v)
#     end
#     @doc.should_receive(:add_text).with(String)
#     
#     @factory.create_document= @doc
#     
#     @node = flexmock("node")
#     @node.should_receive(:put_doc).with(@doc).and_return { true }
#     @factory.create_node= @node
# 
#     
#     
#     @system.add_item(people(:tagged_with_rails_solaris)) 
#   end
# end