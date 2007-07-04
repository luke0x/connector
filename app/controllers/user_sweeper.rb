=begin #(fold)
Copyright 2004-2007 Joyent Inc.

Redistribution and/or modification of this code is governed
by either the GPLv2 or Joyent Commercial Software licenses.

Report issues and contribute at http://dev.joyent.com/

$Id$
=end #(end)

class UserSweeper < ActionController::Caching::Sweeper
  observe User

  def after_save(user)
#    expire_fragment(%r{/sidebar.group_id=\d+})
  end

  def after_destroy(user)
#    expire_fragment(%r{/sidebar.group_id=\d+})
  end
end
