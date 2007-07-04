$:.unshift 'lib'
require 'mockfs/override'
require 'test/ts_mockfs'

class TestOverride < Test::Unit::TestCase
	include TestMockFSAndOverride
	
	def setup
		@file = File
	end
	
	def test_overridden
		dir_path = 'test_dir/subdir'
		MockFS.mock_file_system.fill_path dir_path
		file_path = 'test_dir/subdir/some_file'
		FileUtils.touch file_path
		assert Dir.entries( dir_path ).include?( 'some_file' )
		assert File.exist?( file_path )
	end
	
	def test_mocks_require
		MockFS.file.open( 'required_file.rb', File::CREAT | File::WRONLY ) do |f|
			f << "SOME_CONST = 'foobar'"
		end
		contents = File.open( 'required_file.rb' ) do |f| f.gets( nil ); end
		assert_equal( "SOME_CONST = 'foobar'", contents )
		require 'required_file'
		assert_equal( 'foobar', SOME_CONST )
	end
end
