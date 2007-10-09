=begin #(fold)
++
Copyright 2004-2007 Joyent Inc.

Redistribution and/or modification of this code is 
governed by the GPLv2.

Report issues and contribute at http://dev.joyent.com/

$Id$
--
=end #(end)

module JoyentJob
  class DummyServer
    def add_job(t)
      JoyentJob::Job.from(t).do_it!
    end
  end
end