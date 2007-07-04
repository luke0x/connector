#!/usr/bin/env ruby
#
#  From http://www.yotabanana.com/hiki/ruby-gettext-howto-rails.html
#  Copyright (c) 2003-2007 Masao Mutoh <mutoh@highway.ne.jp>

# If cannot load it, load mockup classes instead
# this will prevent any exception related to calls to _() 
# related functions

unless defined? GetText
  module GetText
    def _(str); str; end
    def s_(str); str; end
    def N_(str); str; end
    def n_(str1, str2); str; end
    def Nn_(str1, str2); str; end
    def bindtextdomain(domain, opts = {}); end
    def textdomain(domain); end
  end
  class ::String
    alias :_old_format_m :%
    def %(args)
      if args.kind_of?(Hash)
        ret = dup
        args.each {|key, value|
          ret.gsub!(/\%\{#{key}\}/, value.to_s)
        }
        ret
      else
        ret = gsub(/%\{/, '%%{')
        begin
          ret._old_format_m(args)
        rescue ArgumentError
          $stderr.puts "  The string:#{ret}"
          $stderr.puts "  args:#{args.inspect}"
        end
      end
    end
  end
end