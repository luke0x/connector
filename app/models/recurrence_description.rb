=begin #(fold)
++
Copyright 2004-2007 Joyent Inc.

Redistribution and/or modification of this code is 
governed by the GPLv2.

Report issues and contribute at http://dev.joyent.com/

$Id$
--
=end #(end)

class RecurrenceDescription < Struct

  def self.descriptions(freq)
    case freq
    when :daily       then self.new("Daily", "FREQ=DAILY", 1, 86400, nil)
    when :weekly      then self.new("Weekly", "FREQ=WEEKLY", 2, 604800, nil)
    when :monthly     then self.new("Monthly", "FREQ=MONTHLY", 3, -1, {:months => 1})
    when :yearly      then self.new("Yearly", "FREQ=YEARLY", 4, -1, {:years => 1})
    when :fortnightly then self.new("Fortnightly", "FREQ=WEEKLY;INTERVAL=2", 5, 1209600, nil)
    end
  end
  
end