require 'rubygems'
require 'vendor/gems/mockfs-0.1.6/lib/mockfs.rb'

MockFS.mock = true
MockFS.mock_file_system.clone_real_directory_under JoyentConfig.storage_root, 'test/fixtures/storage_root'
MockFS.mock_file_system.begin
MockFS.file_utils.mv '/home/data/1/users/ian/Documents/foo.jpg', '/home/data/1/users/ian/Pictures/foo.jpg'
MockFS.dir.entries '/home/data/1/users/ian/Documents'
MockFS.mock_file_system.rollback!
MockFS.dir.entries '/home/data/1/users/ian/Documents'
MockFS.file_utils.mv '/home/data/1/users/ian/Documents/foo.jpg', '/home/data/1/users/ian/Pictures/foo.jpg'
MockFS.dir.entries '/home/data/1/users/ian/Documents'
