=begin #(fold)
Copyright 2004-2007 Joyent Inc.

Redistribution and/or modification of this code is governed
by either the GPLv2 or Joyent Commercial Software licenses.

Report issues and contribute at http://dev.joyent.com/

$Id$
=end #(end)

require File.dirname(__FILE__) + '/../test_helper'

class JoyentFileTypeTest < Test::Unit::TestCase
  fixtures all_fixtures

  def test_previewable
    assert JoyentFileType.new('png').previewable?
    assert ! JoyentFileType.new('xls').previewable?
  end

  def test_known
    assert_equal JoyentFileType.new('png').mime_type, 'image/png'
  end
  
  def test_unknown
    assert_equal JoyentFileType.new('unknown').description, 'Unknown Type'
  end
  
  def test_regression_for_2639
    assert_equal JoyentFileType.new(nil).description, 'Unknown Type'
  end

  def test_all_types
    JoyentFileType.types.each do |type|
      assert_equal type[0], JoyentFileType.new(type[0], type[1], type[2], type[3], type[4]).regex
    end
  end
  
end
