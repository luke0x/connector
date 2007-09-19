=begin #(fold)
Copyright 2004-2007 Joyent Inc.

Redistribution and/or modification of this code is governed
by either the GPLv2 or Joyent Commercial Software licenses.

Report issues and contribute at http://dev.joyent.com/

$Id$
=end #(end)

class Bookmark < ActiveRecord::Base
  include JoyentItem

  validates_presence_of :bookmark_folder_id
  validates_presence_of :uri
  validates_presence_of :title

  belongs_to :bookmark_folder

  before_save    :tweak_uri
  before_save    :generate_sha1 # do after :tweak_uri
  before_save    :destroy_icon!
  after_save     :create_icon!
  before_destroy :destroy_icon!

  cattr_accessor :thumbnail_server

  def self.search_fields
    [
      'users.username',
      'bookmarks.uri',
      'bookmarks.title',
      'bookmarks.notes'
    ]
  end

  def name
    title
  end

  def class_humanize
    'Bookmark'
  end

  def use_count
    owner.organization.bookmarks.find(:all, :conditions => ["uri_sha1 = ?", uri_sha1], :scope => :read).length
  end

  def user_count
    owner.organization.bookmarks.find(:all, :conditions => ["uri_sha1 = ?", uri_sha1], :scope => :read).map(&:owner).uniq.length
  end
  
  def first_user
    owner.organization.bookmarks.find(:first, :conditions => ["uri_sha1 = ?", uri_sha1], :order => 'created_at ASC', :scope => :read).owner
  end

  def first_bookmarked_at
    owner.organization.bookmarks.find(:first, :conditions => ["uri_sha1 = ?", uri_sha1], :order => 'created_at ASC', :scope => :read).created_at
  end

  def bookmarked_by?(user)
    ! user.bookmarks.find_by_uri_sha1(uri_sha1).blank?
  end
  
  def copy_to(new_bookmark_folder)
    new_bookmark = new_bookmark_folder.bookmarks.create(self.attributes)
    new_bookmark.owner = new_bookmark_folder.owner
    new_bookmark.save
    permissions.each{|p| new_bookmark.permissions.create(p.attributes)}
    new_bookmark
  end

  def create_icon!
    # don't re-create if it's less than 5 minutes old
    return if MockFS.file.exist?(self.icon_path) and (File.mtime(self.icon_path) > 5.minutes.ago)
    
    @@thumbnail_server.generate_thumbnail(JoyentConfig.mongrel_cluster_host, self.organization.id.to_s, self.uri)
  rescue
    # everything for now til this is all in
    RAILS_DEFAULT_LOGGER.info("Bookmark thumbnail generation: error with id=#{self.id} uri=#{self.uri}")
  end
  
  def destroy_icon!
    return if     self.use_count > 1
    return unless MockFS.file.exist?(self.icon_path)

    begin
      MockFS.file.delete(self.icon_path)
    rescue Errno::ENOENT
      # The thumbnail isn't there, likely because the stupid xserve is down.
    end
  end

  def icon_url
    if MockFS.file.exist?(self.icon_path)
      "/bookmarks/#{self.organization.id}/#{self.uri_sha1}-clipped.png"
    else
      "/images/bookmarks/cameraShy.png"
    end
  end
  
#  def post_to_delicious!
#    hash = {
#      :url => uri,
#      :description => title,
#      :extended => notes,
#      :dt => 
#      :tags => tags.collect{|t| t.gsub(/\s/, '')}.join(' ')
#    }
#    hash[:shared] = 'no' if private?
#
#    post "/v1/posts/add", hash
#  end

  protected
  
    def icon_path
      File.join(File.expand_path(RAILS_ROOT), 'public', 'bookmarks', self.organization.id.to_s, "#{self.uri_sha1}-clipped.png")
    end

    def tweak_uri
      self.uri = self.uri.strip
      self.uri = "http://#{self.uri}" unless (self.uri =~ /[a-z]+:/) == 0
    end

    def generate_sha1
      self.uri_sha1 = Digest::SHA1.hexdigest(self.uri)
    end

end