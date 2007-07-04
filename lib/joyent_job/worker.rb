=begin #(fold)
Copyright 2004-2007 Joyent Inc.

Redistribution and/or modification of this code is governed
by either the GPLv2 or Joyent Commercial Software licenses.

Report issues and contribute at http://dev.joyent.com/

$Id$
=end #(end)

require 'joyent_job/job'
require 'joyent_job/server'

module JoyentJob
  class Worker
    @@wait_times = [1,5,10,15,30,60]

    def initialize(server, logger)
      @server = server
      @wait_time = 1
      @logger = logger
    end
    
    def work
      loop do
        hash = @server.next_job
        if hash
          @logger.info "got job #{hash.inspect}"
          job  = JoyentJob::Job.from hash
          @wait_time = 1

          begin
            @logger.info "working on #{job.description}"
            job.do_it!
            @logger.info "finished with #{job.description}"
          rescue => exception
            @logger.info "#{job.description} failed"
            @logger.error exception
            @server.failed(job.to_h, exception)
            sleep 1 # exceptions should be constant
          end
        else
          sleep wait_time
        end
      end
    end
    
    def wait_time
      return @wait_time if @wait_time == @@wait_times.last

      previous_index = @@wait_times.index @wait_time
      @wait_time = @@wait_times[previous_index + 1]
    end
  end
end