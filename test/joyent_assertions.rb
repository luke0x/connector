=begin #(fold)
++
Copyright 2004-2007 Joyent Inc.

Redistribution and/or modification of this code is 
governed by the GPLv2.

Report issues and contribute at http://dev.joyent.com/

$Id$
--
=end #(end)

module JoyentAssertions
  def assert_xml(str)
    REXML::Document.new(str)
  rescue
    fail "is not xml"
  end
  
  def assert_smart_group_attributes_assigned(sgd)
    sgd.smart_group_attribute_descriptions.each do |att|
      assert @response.body.index("SmartGroup.attributeDescriptions.push(['#{att.id}', '#{att.name}']);"), "#{att.id}-#{att.name} was not in the response body"
    end
  end
  
  def assert_layout
    html = '<html xmlns="http://www.w3.org/1999/xhtml" xml:lang="en" lang="en">'
    assert @response.body =~ /#{html}/
  end
  
  def assert_no_layout
    html = '<html xmlns="http://www.w3.org/1999/xhtml" xml:lang="en" lang="en">'
    assert_nil @response.body =~ /#{html}/
  end

  def assert_toolbar(active_buttons=[])
    active_buttons.each do |button|
      assert toolbar_contains?(button), "doesn't contain '#{button}'"
    end
  end

  private
  
    def toolbar_contains?(button)
      !! case button
        when :quota             then @response.body =~ /<div id="graph">/i
        when :all_notifications then @response.body =~ /show all/i
        when :new_notifications then @response.body =~ /show new/i
        when :import            then @response.body =~ /<a[^>]*>[^<]*#{button}[^<]*<\/a>/i
        when :list, :month      then @response.body =~ /<li class="action#{button}View">/i
        when :copy              then (@response.body =~ /<li class="actionCopy">/i) || (@response.body =~ /<li class="actionCopyDirect">/i)
        else
          @response.body =~ /<li class="action#{button}">/i
      end
    end
end