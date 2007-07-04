=begin #(fold)
Copyright 2004-2007 Joyent Inc.

Redistribution and/or modification of this code is governed
by either the GPLv2 or Joyent Commercial Software licenses.

Report issues and contribute at http://dev.joyent.com/

$Id$
=end #(end)

require 'joyent_job/job'
require 'joyent_job/worker'

module JoyentJob
  class Server
    def initialize(logger)
      @jobs = []
      @failed_jobs = []
      @logger = logger
      @jobs_mutex = Mutex.new
      @jobs_count = 0
      restore_jobs
    end

    def add_job(h)
      job = JoyentJob::Job.from h
      @logger.info "adding job #{job.description}"
      @jobs_mutex.synchronize do
        @jobs_count += 1
        @jobs << h
      end
    end

    def next_job
      @jobs_mutex.synchronize do
        @jobs.shift
      end
    end

    def failed(h, ex)
      job = JoyentJob::Job.from h
      @logger.error "#{job.description} failed with #{ex}"
      @failed_jobs << [h, ex]
    end
    
    def shut_down
      @jobs_mutex.synchronize do
        unless @jobs.empty?
          db =  PStore.new(db_location)
          db.transaction do
            db[:jobs] = @jobs
          end
          @jobs = []
        end
        exit!
      end
    end
    
    def status_string
      "Jobs Pending: #{@jobs.size}\nJobs Failed:  #{@failed_jobs.size}\nTotal Jobs:   #{@jobs_count}"
    end
    
    def db_location
      File.join(RAILS_ROOT, "jobs.pstore")
    end
    
    def restore_jobs
      if File.exists?(db_location)
        db = PStore.new db_location
        db.transaction do
          @jobs = db[:jobs]
        end
        db = nil
        File.unlink(db_location)
      end
    end
  end
end