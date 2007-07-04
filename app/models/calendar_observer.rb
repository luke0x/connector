=begin #(fold)
Copyright 2004-2007 Joyent Inc.

Redistribution and/or modification of this code is governed
by either the GPLv2 or Joyent Commercial Software licenses.

Report issues and contribute at http://dev.joyent.com/

$Id$
=end #(end)

class CalendarObserver < ActiveRecord::Observer
  def after_destroy(calendar)
    # ensure the user always has 1 standard calendar
    return unless User.find_by_id(calendar.user_id)
    
    if calendar.owner.calendars.select{|c| c.parent_id == nil}.blank?
      calendar.owner.calendars.create(:name => calendar.owner.full_name, :parent_id => nil, :organization_id => calendar.organization.id)
    end
  end
end