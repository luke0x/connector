$:.unshift 'lib'
require 'rubygems'
require 'mockfs'
require 'test/unit'

include MockFS

module TestAnyFileSystem
	def setup
		MockFS.mock = mock?
		@dir = MockFS.dir
		@file = MockFS.file
		@file_utils = MockFS.file_utils
		test_dir = 'test'
		@dir.mkdir( test_dir ) unless @file.exist?( test_dir )
		@sandbox_dir = test_dir + '/sandbox'
		@dir.mkdir( @sandbox_dir ) unless @file.exist?( @sandbox_dir )
		@dir.entries( @sandbox_dir ).each do |entry|
			delete_node( entry, @sandbox_dir ) unless %w( . .. ).include? entry
		end
		@local_dir = 'local_dir'
	end
	
	def teardown
		@dir.delete( @local_dir ) if @file.exist?( @local_dir )
		%w( tmp/subdir tmp ).each { |dir_to_delete|
			@dir.delete( dir_to_delete ) if @file.exist?( dir_to_delete )
		}
		%w( in_this_dir testfile ).each { |file_to_delete|
			if @file.exist?( file_to_delete )
				@file.chmod( 0777, file_to_delete )
				@file.delete( file_to_delete )
			end
		}
	end
	
	def assert_file_contents( file, match )
		contents = @file.open( file, File::RDONLY ) do |f| f.gets( nil ); end
		assert_equal( match, contents )
	end
	
	def assert_glob_equal( desired, glob, flags = 0 )
		desired = desired.map { |d| File.join( @sandbox_dir, d ) }
		glob = File.join( @sandbox_dir, glob )
		result_sets = [ @dir.glob( glob, flags ) ]
		result_sets << @dir[glob] unless flags != 0
		result_sets.each do |results|
			assert_equal(
				desired.size, results.size,
				"Desired: #{ desired.inspect }, results: #{ results.inspect }"
			)
			desired.each do |d|
				assert(
					results.include?( d ), "Couldn't find #{ d } in #{ results.inspect }"
				)
			end
		end
	end
	
	def delete_node( entry, parent_dir )
		full_path = File.join( parent_dir, entry )
		begin
			@dir.new( full_path )
			@dir.entries( full_path ).each do |subentry|
				delete_node( subentry, full_path ) unless %w( . .. ).include? subentry
			end
			@dir.delete( full_path )
		rescue Errno::ENOTDIR
			@file.delete( full_path )
		end
	end
	
	def test_chmod
		@file.open( 'testfile', File::CREAT | File::WRONLY ) { |file|
			file.puts 'contents'
		}
		@file.chmod( 000, 'testfile' )
		assert_raise( Errno::EACCES ) { @file.open( 'testfile' ) { |file| } }
	end
	
	def test_cp
		@file_utils.touch( 'testfile' )
		assert( @file.exist?( 'testfile' ) )
		@file_utils.cp( 'testfile', 'testfile2' )
		assert( @file.exist?( 'testfile' ) )
		assert( @file.exist?( 'testfile2' ) )
		@file_utils.cp( 'testfile', @sandbox_dir )
		assert( @file.exist?( 'testfile' ) )
		assert( @file.exist?( File.join( @sandbox_dir, 'testfile' ) ) )
		@file.open( 'testfile', File::CREAT | File::WRONLY ) do |file|
			file.puts 'contents'
		end
		assert_equal( "contents\n", @file.read( 'testfile' ) )
		dest = File.join( @sandbox_dir, 'testfile' )
		@file_utils.cp( 'testfile', dest )
		assert_equal( "contents\n", @file.read( 'testfile' ) )
		assert_equal( "contents\n", @file.read( dest ) )
	end
	
	def test_delete
		subdir1 = @sandbox_dir + '/dir1'
		@dir.mkdir( subdir1 )
		assert( @file.exist?( subdir1 ) )
		@dir.delete( subdir1 )
		assert( !@file.exist?( subdir1 ) )
		file = @sandbox_dir + '/file1'
		@file_utils.touch( file )
		@file.delete( file )
		assert( !@file.exist?( file ) )
	end
	
	def test_directory?
		assert @file.directory?( @sandbox_dir )
		file = @sandbox_dir + '/file1'
		@file_utils.touch file
		assert !@file.directory?( file )
		assert !@file.directory?( 'i/dont/exist' )
	end

	def test_entries
		assert_equal( %w( . .. ), @dir.entries( @sandbox_dir ) )
		assert_equal( %w( . .. ), @dir.new( @sandbox_dir ).entries )
		assert_equal( %w( . .. ), @dir.entries( @sandbox_dir + '/' ) )
		subdir1 = @sandbox_dir + '/dir1'
		@dir.mkdir( subdir1 )
		assert_equal( %w( . .. dir1 ), @dir.entries( @sandbox_dir ) )
		assert_equal( %w( . .. dir1 ), @dir.new( @sandbox_dir ).entries )
		assert_equal(
			%w( . .. dir1 ), @dir.entries( @sandbox_dir + '/../sandbox' )
		)
		file_to_create = File.join( @sandbox_dir, 'file' )
		@file.open( file_to_create, File::CREAT | File::WRONLY ) { |file|
			file.puts( 'testing' )
		}
		assert_equal( %w( . .. dir1 file ), @dir.entries( @sandbox_dir ) )
		assert_equal( %w( . .. dir1 file ), @dir.new( @sandbox_dir ).entries )
		begin
			@dir.entries( '/somewhere/else/' )
			fail "should raise Errno::ENOENT"
		rescue Errno::ENOENT => err
			assert_equal( 'No such file or directory - /somewhere/else/', err.to_s )
		end
	end
	
	def test_exist?
		assert( @file.exist?( @sandbox_dir ) )
		assert( @file.exists?( @sandbox_dir ) )
		assert( @file.exist?( @sandbox_dir + '/' ) )
		file_to_create = File.join( @sandbox_dir, 'file' )
		assert( !@file.exist?( file_to_create ) )
		@file.open( file_to_create, File::CREAT | File::WRONLY ) { |file|
			file.puts( 'testing' )
		}
		assert( @file.exist?( file_to_create ) )
		assert( @file.exist?( @sandbox_dir + '/../sandbox/file' ) )
	end
	
	def test_file?
		assert !@file.file?( @sandbox_dir )
		file = @sandbox_dir + '/file1'
		@file_utils.touch file
		assert @file.file?( file )
		assert !@file.file?( 'i/dont/exist' )
	end
	
	def test_foreach
		ary = []
		@dir.foreach( @sandbox_dir ) do |filename| ary << filename; end
		assert( ary.include?( '.' ) )
		assert( ary.include?( '..' ) )
	end
	
	def test_glob
		%w( config.h main.rb ).each do |name|
			@file_utils.touch File.join( @sandbox_dir, name )
		end
		@dir.mkdir( File.join( @sandbox_dir, 'lib' ) )
		@file_utils.touch File.join( @sandbox_dir, 'lib', 'song.rb' )
		@dir.mkdir( File.join( @sandbox_dir, 'lib', 'song' ) )
		@file_utils.touch File.join( @sandbox_dir, 'lib', 'song', 'karaoke.rb' )
		assert_glob_equal( [ 'config.h' ], 'config.?' )
		assert_glob_equal( [], 'configg.?' )
		assert_glob_equal( [ 'main.rb' ], '*.[a-z][a-z]' )
		assert_glob_equal( [ 'config.h' ], '*.[^r]*' )
		assert_glob_equal( [ 'main.rb', 'config.h' ], "*.{rb,h}" )
		assert_glob_equal( [ 'main.rb', 'config.h', 'lib' ], "*" )
		assert_glob_equal(
			[".", "..", "config.h", "main.rb", 'lib'], "*", File::FNM_DOTMATCH
		)
		rbfiles = File.join("**", "*.rb")
		assert_glob_equal(
			["main.rb", "lib/song.rb", "lib/song/karaoke.rb"], rbfiles
		)
		libdirs = File.join("**", "lib")
		assert_glob_equal( ["lib"], libdirs )
		librbfiles = File.join("**", "lib", "**", "*.rb")
		assert_glob_equal( ["lib/song.rb", "lib/song/karaoke.rb"], librbfiles )
		librbfiles = File.join("**", "lib", "*.rb")
		assert_glob_equal( ["lib/song.rb"], librbfiles )
	end
	
	def test_mkdir
		@dir.mkdir( @local_dir )
		assert( @file.exist?( @local_dir ) )
		if @file.exist?( './tmp' )
			@dir.entries( './tmp' ).each { |entry|
				unless %w( . .. ).include?( entry )
					@dir.delete( File.join( './tmp', entry ) )
				end
			}
			@dir.delete( './tmp' )
		end
		@dir.mkdir( './tmp' )
		assert( @file.exist?( './tmp' ) )
		@dir.mkdir( './tmp/subdir' )
		assert( @file.exist?( './tmp/subdir' ) )
	end
	
	def test_mkpath
		subsubdir = File.join( @sandbox_dir, 'subdir1', 'subdir2' )
		@file_utils.mkpath subsubdir
		assert_equal( [ '.', '..' ], @dir.entries( subsubdir ) )
	end
	
	def test_mtime
		assert_not_nil( @file.mtime( @sandbox_dir ) )
		sleep 1
		subdir1 = @sandbox_dir + '/dir1'
		@dir.delete( subdir1 ) if @file.exist?( subdir1 )
		@dir.mkdir( subdir1 )
		assert_equal( @file.mtime( subdir1 ), @file.mtime( @sandbox_dir ) )
		sleep 1
		file_to_create = File.join( @sandbox_dir, 'file' )
		@file.open( file_to_create, File::CREAT | File::WRONLY ) { |file|
			file.puts( 'testing' )
		}
		assert_equal( @file.mtime( @sandbox_dir ), @file.mtime( file_to_create ) )
		assert_raise( Errno::ENOENT ) { @file.mtime( 'i/dont/exist' ) }
	end
	
	def test_mv
		file1 = @sandbox_dir + '/file1'
		file2 = @sandbox_dir + '/file2'
		@file_utils.touch( file1 )
		assert( @file.exist?( file1 ) )
		assert( !@file.exist?( file2 ) )
		@file_utils.mv( file1, file2 )
		assert( !@file.exist?( file1 ) )
		assert( @file.exist?( file2 ) )
		file3 = @sandbox_dir + '/subdir/file3'
		@dir.mkdir( @sandbox_dir + '/subdir' )
		@file_utils.mv( file2, file3 )
		assert( !@file.exist?( file2 ) )
		assert( @file.exist?( file3 ) )
		@file_utils.mv( file3, file1 )
		assert( !@file.exist?( file3 ) )
		assert( @file.exist?( file1 ) )
		assert_raise( Errno::ENOENT ) { @file_utils.mv( file3, file1 ) }
		hash = { :a => 1 }
		@file.open( 'dump', File::CREAT | File::WRONLY ) { |f|
			f << Marshal.dump( hash )
		}
		contents = @file.open( 'dump' ) { |f| f.readlines.join }
		assert_equal( hash, Marshal.load( contents ) )
		@file_utils.mv( 'dump', 'dump-somewhere-else' )
		contents = @file.open( 'dump-somewhere-else' ) { |f| f.readlines.join }
		assert_equal( hash, Marshal.load( contents ) )
		@file_utils.move( 'dump-somewhere-else', 'dump' )
		assert( !@file.exist?( 'dump-somewhere-else' ) )
		assert( @file.exist?( 'dump' ) )
		@file_utils.mv( 'dump', @sandbox_dir )
		assert( !@file.exist?( 'dump' ) )
		assert( @file.exist?( File.join( @sandbox_dir, 'dump' ) ) )
	end
	
	def test_open
		file_to_create = File.join( @sandbox_dir, 'file' )
		assert_raise( Errno::ENOENT ) {
			@file.open( file_to_create, File::RDONLY ) { |file| }
		}
		assert_raise( Errno::ENOENT ) {
			@file.open( file_to_create, 'r' ) { |file| }
		}
		@file.open( file_to_create, File::CREAT | File::WRONLY ) { |file|
			file.puts( 'testing' )
		}
		2.times { assert_file_contents( file_to_create, "testing\n" ) }
		@file.open( file_to_create, File::APPEND | File::WRONLY ) { |file|
			file.puts( 'testing' )
		}
		assert_file_contents( file_to_create, "testing\ntesting\n" )
		@file.delete file_to_create
		@file.open( file_to_create, 'w' ) { |file| file.puts( 'testing' ) }
		2.times { assert_file_contents( file_to_create, "testing\n" ) }
		@file.open( file_to_create, 'a' ) { |file| file.puts( 'testing' ) }
		assert_file_contents( file_to_create, "testing\ntesting\n" )
		perms = File::TRUNC | File::CREAT | File::WRONLY
		@file.open( 'in_this_dir', perms ) { |file| file.puts 'first line' }
		assert_file_contents( 'in_this_dir', "first line\n" )
		@file.open( 'in_this_dir', perms ) { |file| file.puts 'first' }
		assert_file_contents( 'in_this_dir', "first\n" )
		@file.open( 'in_this_dir', 'w' ) { |file| file.puts 'first line' }
		assert_file_contents( 'in_this_dir', "first line\n" )
		@file.open( 'in_this_dir', 'w' ) { |file| file.puts 'first' }
		assert_file_contents( 'in_this_dir', "first\n" )
		value_from_block = @file.open( file_to_create, File::RDONLY ) { |file|
			file.readlines.join
		}
		assert_equal( "testing\ntesting\n", value_from_block )
		value_from_block = @file.open( file_to_create, 'r' ) { |file|
			file.readlines.join
		}
		assert_equal( "testing\ntesting\n", value_from_block )
		perms = File::WRONLY | File::CREAT | File::TRUNC
		@file.open( file_to_create, perms ) { |file| file << 'test' }
		assert_file_contents( file_to_create, 'test' )
		f = @file.open( file_to_create, File::WRONLY | File::APPEND )
		f.write "\ntest 2"
		f.close
		str = @file.open( file_to_create ) do |f| f.gets( nil ); end
		assert_equal( "test\ntest 2", str )
		@file.delete file_to_create
		@file.open( file_to_create, 'w' ) { |file| file << 'test' }
		assert_file_contents( file_to_create, 'test' )
		f = @file.open( file_to_create, 'a' )
		f.write "\ntest 2"
		f.close
		str = @file.open( file_to_create ) do |f| f.gets( nil ); end
		assert_equal( "test\ntest 2", str )
	end
	
	def test_path
		%w( . .. test ).each do |d| assert_equal( d, @dir.new( d ).path ) end
	end
	
	def test_read
		assert_raise( Errno::EISDIR ) do @file.read( @sandbox_dir ); end
		assert_raise( Errno::ENOENT ) do @file.read( 'i/dont/exist' ); end
		@file.open( 'testfile', File::CREAT | File::WRONLY ) { |file|
			file.puts 'contents'
		}
		assert_equal( "contents\n", @file.read( 'testfile' ) )
		assert_equal( "contents\n", @file.read( 'testfile' ) )
		empty = @sandbox_dir + '/empty'
		@file_utils.touch empty
		assert_equal( '', @file.read( empty ) )
	end
	
	def test_respond_to?
		assert( @dir.respond_to?( :delete ) )
	end
	
	def test_rmdir
		@dir.mkdir @local_dir
		@dir.rmdir @local_dir
		assert !@file.exist?( @local_dir )
	end
	
	def test_size
		@file.open( 'testfile', File::CREAT | File::WRONLY ) { |file|
			file.puts 'contents'
		}
		assert_equal( 9, @file.size( 'testfile' ) )
	end
	
	def test_touch
		orig_time = @file.mtime( @sandbox_dir )
		sleep 1
		@file_utils.touch( @sandbox_dir )
		assert( orig_time < @file.mtime( @sandbox_dir ) )
		new_file = @sandbox_dir + '/new_file'
		@file.delete( new_file ) if @file.exist?( new_file )
		@file_utils.touch( new_file )
		assert( @file.exist?( new_file ) )
		contents = @file.open( new_file ) { |f| f.gets nil }
		assert_nil( contents )
	end

  # These are Joyent added tests for the Joyent methods
  def test_fu_mkdir_p
  end

  def test_fu_cp_r
    @dir.mkdir('testdir')
		@file_utils.touch( File.join('testdir', 'testfile') )
		assert( @file.exist?( File.join('testdir', 'testfile') ) )
		@file_utils.cp_r( 'testdir', 'testdir2' )
		assert( @file.exist?( 'testdir' ) )
		assert( @file.exist?( 'testdir2' ) )
		assert( @file.exist?( File.join('testdir2', 'testfile') ) )
  end
end

module TestMockFSAndOverride
	def test_dirname
		assert_equal( '.', @file.dirname( 'test' ) )
		assert_equal( '.', @file.dirname( 'test/' ) )
		assert_equal( 'test', @file.dirname( 'test/sandbox' ) )
		assert_equal( '/this/that', @file.dirname( '/this/that/theother' ) )
		assert_equal( '/this/that', @file.dirname( '/this/that/theother/' ) )
		assert_equal( './this/that', @file.dirname( './this/that/theother' ) )
		assert_equal( '~/this/that', @file.dirname( '~/this/that/theother' ) )
		assert_equal( '~/this/that', @file.dirname( '~/this/that/theother/' ) )
		assert_equal( '~frank/this', @file.dirname( '~frank/this/that' ) )
	end
end

if $0 == __FILE__
	class TestFileSystem < Test::Unit::TestCase
		include TestAnyFileSystem
		include TestMockFSAndOverride
	
		def mock?; false; end
		
		def test_dont_dispatch_to_mock_file_system
			assert_raise( NoMethodError ) {
				MockFS.fill_path( '/usr/local/whatever' )
			}
		end
	
		def test_get
			assert_equal( Dir, @dir )
			assert_equal( File, @file )
			assert_raise( NoMethodError ) { MockFS.get_something_else }
		end
	
		def test_mock_file_system
			assert_raise( RuntimeError ) { MockFS.mock_file_system }
		end
	end
	
	class TestMockFile < Test::Unit::TestCase
		def test_clone
			mf = MockFileSystem::MockFile.new( 'parent', 'name', 'contents' )
			str = mf.gets nil
			assert_equal( 'contents', str )
			clone = mf.clone
			assert_equal( MockFileSystem::MockFile, clone.class )
			str = clone.gets nil
			assert_equal( 'contents', str )
			mf2 = MockFileSystem::MockFile.new( 'parent', 'name', nil )
			assert_nil( mf2.gets( nil ) )
			clone2 = mf2.clone
			assert_nil( clone2.gets( nil ) )
		end
	end
	
	class TestMockFileSystem < Test::Unit::TestCase
		include TestAnyFileSystem
		include TestMockFSAndOverride
	
		def mock?; true; end
		
		def test_dispatch_to_mock_file_system
			path = '/usr/local/whatever' 
			MockFS.fill_path( path )
			assert_not_nil( MockFS.mock_file_system.node( path ) )
		end
		
		def test_fill_path
			path = './tmp/some/path'
			mfs = MockFS.mock_file_system
			mfs.fill_path( path )
			assert_not_nil( mfs.node( path ) )
			path2 = '../logs/2004/02'
			mfs.fill_path( path2 )
			assert_not_nil( mfs.node( path2 ) )
		end
		
		def test_flush
			assert( !@file.exist?( 'foobar' ) )
			@dir.mkdir( 'foobar' )
			assert( @file.exist?( 'foobar' ) )
			MockFileSystem.flush
			assert( !@file.exist?( 'foobar' ) )
		end
		
		def test_mock_file_system
			assert_equal( MockFileSystem, MockFS.mock_file_system.class )
		end
	end
	
	class TestPath < Test::Unit::TestCase
		def test_absolute
			assert_match(
				%r{^/.*/subdir$}, Path.new( 'subdir' ).absolute.to_s
			)
			abs_path = '/Users/francis/Tech/mockfs/mockfs/lib/..'
			assert_equal( abs_path, Path.new( abs_path ).absolute.to_s )
			local_path = Path.new( './subdir' ).absolute.to_s
			assert( local_path !~ %r{/\./subdir}, local_path )
		end
	
		def test_brackets
			abs_path = Path.new 'francis/Tech/mockfs/mockfs/lib'
			assert_equal( 'francis', abs_path[0] )
			assert_equal( 'Tech/mockfs/mockfs/lib', abs_path[1..-1] )
			assert_equal( 'Tech/mockfs/mockfs', abs_path[1..-2] )
			assert_equal( 'mockfs/mockfs', abs_path[2..-2] )
		end
	
		def test_strip
			assert_equal(
				'somewhere_else', Path.new( 'somewhere_else/' ).strip.to_s
			)
		end
	end
end