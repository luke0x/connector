=begin #(fold)
Copyright 2004-2007 Joyent Inc.

Redistribution and/or modification of this code is governed
by either the GPLv2 or Joyent Commercial Software licenses.

Report issues and contribute at http://dev.joyent.com/

$Id$
=end #(end)

class AsyncSearchServer
  def initialize(hostname, username, password)
    @real_search = ProductionSearchSystem.new(hostname, username, password)
    @work_queue = []
    @worker_mutex = Mutex.new
  end
  
  def do_work
    @worker_thread = Thread.new(self) do |search_system|
      loop do
        begin
          object, command = search_system.next_item
          if command == :add
            @real_search.add_item(object)
          elsif command == :remove
            @real_search.remove_item(object)
          end
        rescue Exception => e
          print "#{e}\n"
        end
      end
    end
    
    DRb.start_service "druby://#{JoyentConfig.production_search_system_host}:#{JoyentConfig.production_search_system_port}", self
    @worker_thread.join
  end
  
  def add_item(clazz, id)
    @work_queue << [clazz, id, :add]
  end
  
  def remove_item(clazz, id)
    @work_queue << [clazz, id, :remove]
  end
  
  def next_item
    arr = @work_queue.shift
    if arr 
      obj = arr[0].find(arr[1])
      return obj, arr[2]
    else
      return nil, nil
    end 
  end
end