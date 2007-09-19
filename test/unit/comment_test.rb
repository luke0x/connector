=begin #(fold)
Copyright 2004-2007 Joyent Inc.

Redistribution and/or modification of this code is governed
by either the GPLv2 or Joyent Commercial Software licenses.

Report issues and contribute at http://dev.joyent.com/

$Id$
=end #(end)

require File.dirname(__FILE__) + '/../test_helper'

class CommentTest < Test::Unit::TestCase
  fixtures all_fixtures
  include CRUDTest
  
  crud_data 'user_id'          => 1,
            'body'             => 'This picture rocks.',
            'commentable_id'   => 1,
            'commentable_type' => 'JoyentFile'
            
  crud_required 'user_id', 'body'
end
