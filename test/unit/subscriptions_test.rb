=begin #(fold)
Copyright 2004-2007 Joyent Inc.

Redistribution and/or modification of this code is governed
by either the GPLv2 or Joyent Commercial Software licenses.

Report issues and contribute at http://dev.joyent.com/

$Id$
=end #(end)

require File.dirname(__FILE__) + '/../test_helper'

class SubscriptionTest < Test::Unit::TestCase
  fixtures all_fixtures

  # Regression test for case 4041
  def test_non_existent_org_doesnt_return
    u = User.find_by_username 'ian'
    subscriptions = u.subscriptions_to_group_type('Folder')
    assert_equal false, subscriptions.map(&:id).include?(10)
  end
  
end
