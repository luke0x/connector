=begin #(fold)
Copyright 2004-2007 Joyent Inc.

Redistribution and/or modification of this code is governed
by either the GPLv2 or Joyent Commercial Software licenses.

Report issues and contribute at http://dev.joyent.com/

$Id$
=end #(end)

require 'drb'

# uses he but moves the adding and removing of items to a seperate system (script/searchserver)
# should speed things up a bit
class AsyncSearchSystem < ProductionSearchSystem
  def initialize(uri, user, password)
    super
    @drb_connection = DRb::DRbObject.new(nil, "druby://#{JoyentConfig.production_search_system_host}:#{JoyentConfig.production_search_system_port}")
  end
  
  def add_item(i)
    @drb_connection.add_item(i.class, i.id)
  end
  
  def remove_item(i)
    @drb_connection.remove_item(i.class, i.id)
  end
end