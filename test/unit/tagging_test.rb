=begin #(fold)
Copyright 2004-2007 Joyent Inc.

Redistribution and/or modification of this code is governed
by either the GPLv2 or Joyent Commercial Software licenses.

Report issues and contribute at http://dev.joyent.com/

$Id$
=end #(end)

require File.dirname(__FILE__) + '/../test_helper'

class TaggingTest < Test::Unit::TestCase
  fixtures all_fixtures
  include CRUDTest
  
  crud_data 'tag_id'        => 1,
            'tagger_id'     => 1,
            'taggable_id'   => 1,
            'taggable_type' => 'JoyentFile'
            
  crud_required 'tag_id', 'tagger_id', 'taggable_id', 'taggable_type'

  # This is how you can tag an item
  def test_tag_item
    users(:ian).tag_item(joyent_files(:ian_jpg), 'pretty')
    
    tag = Tag.find_by_name('pretty')
    assert tag
    
    tagging = Tagging.find(:first, 
      :conditions => ['tag_id = ? AND tagger_id = ? AND taggable_id = ?',
                      tag.id, users(:ian).id, joyent_files(:ian_jpg).id])
    assert tagging
  end

  def test_untag_item
    assert joyent_files(:ian_jpg).taggings.find(:first, :conditions => ['tagger_id = ? and tag_id = ?', users(:ian).id, tags(:orange).id])
    users(:ian).untag_item(joyent_files(:ian_jpg), 'orange')
    assert !joyent_files(:ian_jpg).taggings.find(:first, :conditions => ['tagger_id = ? and tag_id = ?', users(:ian).id, tags(:orange).id])
  end

end
