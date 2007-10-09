=begin #(fold)
++
Copyright 2004-2007 Joyent Inc.

Redistribution and/or modification of this code is 
governed by the GPLv2.

Report issues and contribute at http://dev.joyent.com/

$Id$
--
=end #(end)

require 'lockfile'

module JoyentMaildir
  module Lockable
    # Try to create a lock file so that only one app process can be syncing
    # the mailboxes at any time.  This will prevent the duplicate proxies
    # that have been plaguing us for a while.  Keep a 15 minute time out on
    # the lock file, in case something gets hosed up and it doesn't get removed.
    def obtain_lock(path, lockfile)
      @lockfile = Lockfile.new File.join(path, lockfile), :retries => 0, :timeout => 0
      @lockfile.lock
      return true
    rescue Lockfile::MaxTriesLockError
      @lock_failed = false
      stat = File::Stat.new(File.join(path, lockfile))
      if (15.minutes.ago > stat.ctime) && !@lock_failed
        @lock_failed = true # So it will only retry once
        MockFS.file.delete File.join(path, lockfile)
        # TODO We should probably be notified of 15 minute old locks
        retry
      end
      return false
    end
    
    def release_lock
      @lockfile.unlock
    rescue Lockfile::UnLockError
      # If it's not locked then whatever
    end
  end
end