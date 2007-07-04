=begin #(fold)
Copyright 2004-2007 Joyent Inc.

Redistribution and/or modification of this code is governed
by either the GPLv2 or Joyent Commercial Software licenses.

Report issues and contribute at http://dev.joyent.com/

$Id$
=end #(end)

require File.dirname(__FILE__) + '/../test_helper'

class InvitationTest < Test::Unit::TestCase
  fixtures all_fixtures

  include CRUDTest

  crud_data 'user_id'     => 1,
            'event_id'    => 1,
            'accepted'    => true,
            'pending'     => false,
            'calendar_id' => nil
            
  crud_required 'user_id', 'event_id'

  def test_accept
    i = invitations(:no_calendar_for_weekly)
    i.accept!(calendars(:anotherthing))
    assert calendars(:anotherthing).events(true).index(events(:weekly))
  end
  
  def test_decline
    i = invitations(:no_calendar_for_weekly)
    i.decline!
    assert !users(:ian).pending_invitations.index(i)
  end
end
