=begin #(fold)
Copyright 2004-2007 Joyent Inc.

Redistribution and/or modification of this code is governed
by either the GPLv2 or Joyent Commercial Software licenses.

Report issues and contribute at http://dev.joyent.com/

$Id$
=end #(end)

require File.dirname(__FILE__) + '/../test_helper'

class NotificationTest < Test::Unit::TestCase
  fixtures all_fixtures
  include CRUDTest

  crud_data 'organization_id' => 1,
            'notifiee_id'     => 1,
            'notifier_id'     => 2,
            'item_id'         => 1,
            'item_type'       => 'JoyentFile',
            'acknowledged'    => false
  
  crud_required 'organization_id', 'notifiee_id', 'notifier_id', 'item_id', 'item_type'
  
  def test_acknowledge
    n = notifications(:ian_check_it)
    n.acknowledge!
    n.reload
    assert n.acknowledged?
  end
end
