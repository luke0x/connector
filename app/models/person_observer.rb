=begin #(fold)
Copyright 2004-2007 Joyent Inc.

Redistribution and/or modification of this code is governed
by either the GPLv2 or Joyent Commercial Software licenses.

Report issues and contribute at http://dev.joyent.com/

$Id$
=end #(end)

class PersonObserver < ActiveRecord::Observer
  def after_save(person)
    if u = person.user
      u.full_name = person.full_name
      u.save
    end
  end
end