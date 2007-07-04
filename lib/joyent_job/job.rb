=begin #(fold)
Copyright 2004-2007 Joyent Inc.

Redistribution and/or modification of this code is governed
by either the GPLv2 or Joyent Commercial Software licenses.

Report issues and contribute at http://dev.joyent.com/

$Id$
=end #(end)

module JoyentJob
  class Job
    cattr_accessor :server
    @@server = JoyentJob::DummyServer.new 
    
    def initialize(clazz, id, method)
      @clazz = clazz
      @id = id
      @method = method
    end
    
    def do_it!
      @clazz.find(@id).send(@method)
    end
    
    # convinient way of submitting jobs when no special information is required
    def submit
      @@server.add_job self.to_h
    end
    
    def to_h
      {:class=>@clazz.to_s, :id=>@id, :method=>@method}
    end
    
    def description
      "#{@clazz}.find(#{@id}).#{@method}"
    end
    
    def self.from(hash)
      if hash
        new hash[:class].constantize, hash[:id], hash[:method]
      else
        nil
      end
    end        
  end
end