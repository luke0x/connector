#!/usr/bin/env ruby
=begin #(fold)
++
Copyright 2004-2007 Joyent Inc.

Redistribution and/or modification of this code is 
governed by the GPLv2.

Report issues and contribute at http://dev.joyent.com/

$Id$
--
=end #(end)

require 'yaml'
require 'net/http'
require 'timeout'

def try_and_get(url, port, expected)
  begin
    Timeout::timeout(5) {
      http = Net::HTTP.new('localhost', port)
      response = http.get(url)
      if response.code == expected
        print "   OK (#{response.code}) #{url}\n"
      else
        print "   ERROR (#{response.code}) #{url}\n"
      end
    }
  rescue Timeout::Error
    print "   ERROR - HUNG #{url}\n"
  end
end

if !File.exist?(File.dirname(__FILE__) + '/../config/mongrel_cluster.yml')
  puts "error, no mongrel_cluster.yml"
  exit
end

mc = YAML::load(open(File.dirname(__FILE__) + '/../config/mongrel_cluster.yml'))

start = mc['port'].to_i
stop  = mc['port'].to_i + mc['servers'] - 1

(start..stop).each do |port|
  pid = open(File.dirname(__FILE__)+"/../log/mongrel.#{port}.pid").read.strip
  puts "Checking port #{port} (pid: #{pid}) ... "
  try_and_get '/noaccount.html', port, '200'
  try_and_get '/login', port, '302'
end
