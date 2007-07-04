#!/usr/bin/env ruby
#
#  Copyright (c) 2006-2007 Joyent Inc. 
#  Licensed under the same terms as Joyent Connector.

begin
  # Try to load gettext gem first
  require 'rubygems'
  # 1.8.0 gem is buggy for rails 1.2+.
  if Kernel.respond_to? :gem
    gem 'gettext', '>= 1.9.0'
  else
    require_gem 'gettext', '>= 1.9.0'
  end
  require 'gettext/rails'
    
rescue LoadError
  # If cannot load it, load mockup classes instead
  # this will prevent any exception related to calls to _() 
  # related functions
  unless defined? GetText
    require File.join(File.dirname(__FILE__),'lib/pseudo_gettext')
  end
  RAILS_DEFAULT_LOGGER.warn "#{$!}"
ensure
  require File.join(File.dirname(__FILE__),'lib/gettextilize')
  ActionController::Base.send(:include,ActionController::Gettextilize)
end