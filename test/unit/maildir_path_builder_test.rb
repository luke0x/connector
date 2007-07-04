=begin #(fold)
Copyright 2004-2007 Joyent Inc.

Redistribution and/or modification of this code is governed
by either the GPLv2 or Joyent Commercial Software licenses.

Report issues and contribute at http://dev.joyent.com/

$Id$
=end #(end)

require File.dirname(__FILE__) + '/../test_helper'
require 'pathname'

context "A path builder" do
  def setup
    @maildir_root = Pathname.new(ENV['JOYENT_MAILDIR'] || '/home/vmail').cleanpath.to_s
  end
  
  specify "builds path to INBOX.foo properly" do
    target = "#{@maildir_root}/foo.com/scott/Maildir/.foo"

    assert_equal target, JoyentMaildir::MaildirPath.build('foo.com', 'scott', 'INBOX.foo')
  end
  
  specify "builds a path to INBOX.foo.bar properly" do
    target = "#{@maildir_root}/foo.com/scott/Maildir/.foo.bar"
    
    assert_equal target, JoyentMaildir::MaildirPath.build('foo.com', 'scott', 'INBOX.foo.bar')
  end
  
  specify "handles INBOX properly" do
    target = "#{@maildir_root}/foo.com/scott/Maildir"
    
    assert_equal target, JoyentMaildir::MaildirPath.build('foo.com', 'scott', 'INBOX')
  end
end
