=begin #(fold)
Copyright 2004-2007 Joyent Inc.

Redistribution and/or modification of this code is governed
by either the GPLv2 or Joyent Commercial Software licenses.

Report issues and contribute at http://dev.joyent.com/

$Id$
=end #(end)

require "#{File.dirname(__FILE__)}/../test_helper"

class SubscriptionsIntegration < ActionController::IntegrationTest
  fixtures all_fixtures
  
  # Tests to make sure when clicking on a subscription group, it does not expand that user in Others' Groups
  ['/mail/11', '/calendar/3', '/files/11', '/people/2' '/bookmarks/2'].each do |url|
    define_method "test_should_not_expand_#{url.gsub('/', '_')}" do
      new_session_as(:ian) do |sess|
        sess.get url
        # debugger
        sess.assert_select "div#groupsOthers[class=collapsiblePalette expanded]", false
      end
    end
  end

end