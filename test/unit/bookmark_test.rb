=begin #(fold)
Copyright 2004-2007 Joyent Inc.

Redistribution and/or modification of this code is governed
by either the GPLv2 or Joyent Commercial Software licenses.

Report issues and contribute at http://dev.joyent.com/

$Id$
=end #(end)

require File.dirname(__FILE__) + '/../test_helper'

class BookmarkTest < Test::Unit::TestCase
  fixtures all_fixtures
  include CRUDTest
  
  crud_data 'organization_id'    => 1,
            'user_id'            => 1,
            'bookmark_folder_id' => 1,
            'uri'                => 'http://www.joyent.com',
            'uri_sha1'           => 'c2b1ec468226eb80ba2d052a76279208b4eeeccb',
            'title'              => 'Joyent Homepage',
            'notes'              => 'yo'
            
  crud_required 'organization_id', 'user_id', 'bookmark_folder_id', 'uri', 'title'

  def setup                       
    User.current = users(:ian)
  end

  def test_crud
    run_crud_tests
  end

  def test_sha1_generated
    b = bookmarks(:ian_bookmark_1)
    b.uri = "yo"
    b.save

    assert_equal b.uri_sha1, Digest::SHA1.hexdigest(b.uri)
  end

  def test_use_count
    b = bookmarks(:ian_bookmark_1)
    assert_equal 1, b.use_count

    users(:peter).bookmarks.create(:organization_id => 1, :bookmark_folder_id => 2, :uri => b.uri, :title => 'whatever')
    assert_equal 2, b.use_count

    # use count should include dupes by the same user
    users(:peter).bookmarks.create(:organization_id => 1, :bookmark_folder_id => 2, :uri => b.uri, :title => 'whatever')
    assert_equal 3, b.use_count
  end

  def test_user_count
    b = bookmarks(:ian_bookmark_1)
    assert_equal 1, b.user_count

    users(:peter).bookmarks.create(:organization_id => 1, :bookmark_folder_id => 2, :uri => b.uri, :title => 'whatever')
    assert_equal 2, b.user_count

    # user count should not include dupes by the same user
    users(:peter).bookmarks.create(:organization_id => 1, :bookmark_folder_id => 2, :uri => b.uri, :title => 'whatever')
    assert_equal 2, b.user_count
  end

  def test_first_user
    User.current = users(:ian)

    b = bookmarks(:ian_bookmark_1)
    assert_equal users(:ian), b.first_user

    users(:peter).bookmarks.create(:organization_id => 1, :bookmark_folder_id => 2, :uri => b.uri, :title => 'whatever')
    assert_equal users(:ian), b.first_user
  end

  def test_first_bookmarked_at
    User.current = users(:ian)

    b = bookmarks(:ian_bookmark_1)
    assert_equal b.created_at, b.first_bookmarked_at

    b2 = users(:peter).bookmarks.create(:organization_id => 1, :bookmark_folder_id => 2, :uri => b.uri, :title => 'whatever')
    assert_equal b.created_at, b2.first_bookmarked_at
  end

  def test_bookmarked_by
    assert_equal bookmarks(:ian_bookmark_1).owner, users(:ian)
    assert bookmarks(:ian_bookmark_1).bookmarked_by?(users(:ian))
  end

  def test_copy_to
    assert_nil users(:peter).bookmarks.find_by_uri(bookmarks(:ian_bookmark_1).uri)
    bookmarks(:ian_bookmark_1).copy_to(bookmark_folders(:peter_bookmark_folder))
    assert_equal 1, users(:peter).bookmarks.select{|b| b.uri == bookmarks(:ian_bookmark_1).uri}.length
  end

  # regression for case 3767
  def test_bookmark_stats_limited_to_org
    uri = 'http://www.joyent.com'

    b_o1 = organizations(:joyent).bookmarks.find_by_uri(uri)
    b_o2 = organizations(:textdrive).bookmarks.find_by_uri(uri)
    assert_not_equal b_o1, b_o2

    User.current = b_o1.owner
    b_o1_use_count = b_o1.use_count
    b_o1_user_count = b_o1.user_count
    b_o1_first_user = b_o1.first_user
    b_o1_first_bookmarked_at = b_o1.first_bookmarked_at

    User.current = b_o2.owner
    b_o2_use_count = b_o2.use_count
    b_o2_user_count = b_o2.user_count
    b_o2_first_user = b_o2.first_user
    b_o2_first_bookmarked_at = b_o2.first_bookmarked_at
    
    assert_equal (b_o1_use_count + b_o2_use_count), Bookmark.find_all_by_uri(uri).length
    assert_equal (b_o1_user_count + b_o2_user_count), Bookmark.find_all_by_uri(uri).map(&:owner).uniq.length
    assert_not_equal b_o1_first_user, b_o2_first_user
    assert_not_equal b_o1_first_bookmarked_at, b_o2_first_bookmarked_at
  end

  def test_tweak_uri
    test_uris_same    = ["http://joyent.com", "https://connector.joyent.com/", "callto:+18005551212", "hthttp://google.com"]
    test_uris_prepend = ["google.com", "http.net", "invalid,whatever"]
    test_uris_encode  = ["http://www.google.com/search?q=ruby+on+rails#anchor"]
    b = bookmarks(:ian_bookmark_1)

    test_uris_same.each do |uri|
      b.update_attributes(:uri => uri)
      assert_equal uri, b.uri
    end
    test_uris_prepend.each do |uri|
      b.update_attributes(:uri => uri)
      assert_equal "http://#{uri}", b.uri
    end
    test_uris_encode.each do |uri|
      b.update_attributes(:uri => uri)
      assert_equal "http://www.google.com/search?q=ruby+on+rails#anchor", b.uri
    end
  end
  
  def test_class_humanize
    assert_equal "Bookmark", bookmarks(:ian_bookmark_1).class_humanize
  end                                                                 
  
  def test_name
    assert_equal "Joyent Homepage", bookmarks(:ian_bookmark_1).name
  end                                                              
  
  def test_icon_url_cameray_shy
    assert_equal "/images/bookmarks/cameraShy.png", bookmarks(:ian_bookmark_1).icon_url
  end                          
  
  def test_icon_url_good
    MockFS.mock = true           
    icon_path   = bookmarks(:ian_bookmark_1).send(:icon_path)
    
    MockFS.fill_path File.dirname(icon_path)
    
    MockFS.file.open(icon_path, File::CREAT ) do |f|
      f.puts "image content"
    end                    
    
    assert_equal "/bookmarks/1/#{bookmarks(:ian_bookmark_1).uri_sha1}-clipped.png", bookmarks(:ian_bookmark_1).icon_url    
  end               
  
  def test_destroy_icon
    MockFS.mock = true           
    icon_path   = bookmarks(:ian_bookmark_1).send(:icon_path)
    
    MockFS.fill_path File.dirname(icon_path)
    
    MockFS.file.open(icon_path, File::CREAT ) do |f|
      f.puts "image content"
    end
           
    assert MockFS.file.exist?(icon_path)
   
    bookmarks(:ian_bookmark_1).destroy_icon!
    
    assert !MockFS.file.exist?(icon_path)
  end
end