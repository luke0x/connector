=begin #(fold)
++
Copyright 2004-2007 Joyent Inc.

Redistribution and/or modification of this code is 
governed by the GPLv2.

Report issues and contribute at http://dev.joyent.com/

$Id$
--
=end #(end)

class RunAs
  def self.run_as(uid, gid, &block)
    ouid = Process.euid
    ogid = Process.egid
    Process::Sys.setegid gid
    Process::Sys.seteuid uid
    yield
  ensure
    Process::Sys.seteuid ouid
    Process::Sys.setegid ogid
  end
end
