=begin #(fold)
Copyright 2004-2007 Joyent Inc.

Redistribution and/or modification of this code is governed
by either the GPLv2 or Joyent Commercial Software licenses.

Report issues and contribute at http://dev.joyent.com/

$Id$
=end #(end)

require File.dirname(__FILE__) + '/../test_helper'

class WebsiteTest < Test::Unit::TestCase
  fixtures all_fixtures
  include CRUDTest
  
  crud_data 'person_id'  => 1,
            'preferred'  => true,
            'site_title' => 'Joyent',
            'site_url'   => 'http://joyent.com'

  crud_required 'site_title', 'site_url' #, 'person_id'

  def test_site_url_transformation
    ws = assert_create

    ws.update_attribute :site_url, 'google.com'

    assert_equal 'http://google.com', ws.reload.site_url

    ws.update_attribute :site_url, 'http://textdrive.com'
    assert_equal 'http://textdrive.com', ws.reload.site_url
  end
  
  def test_sorting
    assert_equal 1, people(:ian).websites.first.id
  end
  
  # regression for case 2851
  def test_person_saved_on_save
    person_time = websites(:first).person.updated_at
    websites(:first).save
    assert_not_equal person_time, websites(:first).person.updated_at
  end

  # regression for case 2851
  def test_person_saved_on_destroy
    person_time = websites(:first).person.updated_at
    websites(:first).destroy
    assert_not_equal person_time, websites(:first).person.updated_at
  end
end
