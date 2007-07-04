=begin #(fold)
Copyright 2004-2007 Joyent Inc.

Redistribution and/or modification of this code is governed
by either the GPLv2 or Joyent Commercial Software licenses.

Report issues and contribute at http://dev.joyent.com/

$Id$
=end #(end)

require 'fileutils'

class BookmarkGenerator
  def initialize(logger)
    @logger = logger
  end
  
  # generate a thumbnail for the uri and scp the file to the specified path
  def generate_thumbnail(request_host, organization_id, uri)
    fork do
      # ensure storage dir exists
      bookmark_directory = File.join(JoyentConfig.bookmark_generator_save_prefix, request_host, organization_id)
      @logger.info "about to create path #{bookmark_directory}"
      FileUtils.mkdir_p(bookmark_directory) #, :noop => false
      @logger.info "just created path #{bookmark_directory}"

      # generate
      command = "#{JoyentConfig.bookmark_generator_webkit2png_path} -C -D #{bookmark_directory} -o #{Digest::SHA1.hexdigest(uri)}"
      @logger.info "executing command #{command}"
      # Popen here, webkit2png MUST take URLs on stdin, NOT the command line,
      # otherwise there are many possible shell exploits.
      bg = IO.popen(command, 'w+')
      bg.write "#{uri}\n"
      bg.close_write
      result = bg.close_read
      
      @logger.info "result was #{result}"
      if result =~ /something went wrong/ and command[-1..-1] != "/" # maybe try one more time
        @logger.info "executing command #{command}/"
        result = `#{command}/`
        @logger.info "result was #{result}"
      end
      if result =~ /something went wrong/
        @logger.info "something went wrong, exiting thread"
        next
      end
    end

    return true
  end
end