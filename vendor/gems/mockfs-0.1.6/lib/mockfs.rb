# MockFS is a test-obsessed library for mocking out the entire file system.
# It provides mock objects that clone the functionality of File, FileUtils, 
# Dir, and other in-Ruby file-access libraries.
# 
# To use MockFS in your production code, call MockFS.[ class ].
#
#   MockFS.file               => File
#   MockFS.file_utils         => FileUtils
#   MockFS.dir                => Dir
#   MockFS.dir.entries( '.' ) => [".", "..", ...]
#
# Then, to turn these into mock instances for a test case, simply call
#
#   MockFS.mock = true
#
# When you've done this, the normal calls will actually return adapters that
# pretend to be the class in question:
#
#   MockFS.file               => MockFS::FileAdapter
#   MockFS.file_utils         => MockFS::FileUtilsAdapter
#   MockFS.dir                => MockFS::DirAdapter
#   MockFS.dir.entries( '.' ) => [".", "..", ...]
#
# You can get direct access to the enclosed MockFileSystem by calling 
# MockFS.mock_file_system.
#
# == Testing example
#
# For example, let's test a simple function that moves a log file into
# somebody's home directory.
#
#   require 'mockfs'
#
#   def move_log
#     MockFS.file_utils.mv( '/var/log/httpd/access_log', '/home/francis/logs/' )
#   end
#
# A test of this functionality might look like this:
#
#   require 'test/unit'
#
#   class TestMoveLog < Test::Unit::TestCase
#     def test_move_log
#       # Set MockFS to use the mock file system
#       MockFS.mock = true
#
#       # Fill certain directories
#       MockFS.fill_path '/var/log/httpd/'
#       MockFS.fill_path '/home/francis/logs/'
#
#       # Create the access log
#       MockFS.file.open( '/var/log/httpd/access_log', File::CREAT ) do |f|
#         f.puts "line 1 of the access log"
#       end
#
#       # Run the method
#       move_log
#
#       # Test that it was moved, along with its contents
#       assert( MockFS.file.exist?( '/home/francis/logs/access_log' ) )
#       assert( !MockFS.file.exist?( '/var/log/httpd/access_log' ) )
#       contents = MockFS.file.open( '/home/francis/logs/access_log' ) do |f|
#         f.gets( nil )
#       end
#       assert_equal( "line 1 of the access log\n", contents )
#     end
#   end
#
# This test will be successful, and it won't litter your real file-system with 
# testing files.
#
# == override.rb
#
# Reading the testing example above, you may be struck by one thing: Using
# MockFS requires you to remember to reference it everywhere, making calls such
# as MockFS.file_utils.mv instead of just FileUtils.mv. As another option, you
# can use File, FileUtils, and Dir directly, and then in your tests, substitute 
# them by including mockfs/override.rb. I'd recommend using these with caution;
# substituting these low-level classes can have unpredictable results.
#
# Including override.rb also allows Kernel.require to look in your
# mock file system for mock Ruby files to include. You might find this useful
# if you have configuration files written in Ruby, and you'd like to swap them
# out for tests. This is pretty experimental, too.
#
# == Project page
#
# You can view the Rubyforge project page at
# http://rubyforge.org/projects/mockfs.

require 'delegate'
require 'extensions/all'
require 'fileutils'
require 'singleton'
require 'ostruct'

module MockFS
	Version = '0.1.6'

	@@mock = false
	
	def self.method_missing( symbol, *args ) #:nodoc:
		class_name = nil
		if symbol.id2name =~ /^get_(.*)/
			result = self.send( $1, *args )
			warn "MockFS.#{ symbol.id2name } is deprecated, use #{ $1 } instead"
			result
		else
			klass = real_class_or_mock_class symbol
			if klass
				klass
			else
				@@mock ? mock_file_system.send( symbol, *args ) : super
			end
		end
	end
	
	# Tell MockFS whether to offer interfaces to the real or mock file system.
	# +is_mock+ should be a Boolean.
	def self.mock= ( is_mock ); @@mock = is_mock; end
	
	# Returns +true+ or +false+ depending on whether MockFS is using the mock file system.
	def self.mock?; @@mock; end
	
	# If we're in mock mode, this will return the MockFileSystem; otherwise it
	# will raise a RuntimeError.
	def self.mock_file_system
		@@mock ? MockFileSystem.instance : ( raise RuntimeError )
	end
	
	def self.real_class_or_mock_class( symbol ) #:nodoc:
		class_name = symbol.id2name.capitalize
		class_name.gsub!( /_(\w)/ ) { |s| $1.capitalize }
		if %w( Dir File FileUtils ).include?( class_name )
			if @@mock
				Class.by_name( 'MockFS::' + class_name + 'Adapter' )
			else
				Class.by_name( class_name )
			end
		else
			nil
		end
	end
	
	module Adapter #:nodoc:
		@@delegated_methods = [ :delete, :entries, :mtime, :size ]
	
		def method_missing( sym, *args )
			if @@delegated_methods.include?( sym )
				node( args.first ).send( sym )
			else
				super
			end
		end

		def node( nodename ); MockFileSystem.instance.node( nodename ); end
		
		def respond_to?( sym )
			@@delegated_methods.include?( sym ) ? true : super
		end
	end
	
	class DirAdapter #:nodoc:
		extend Adapter
		include Adapter
		
		def self.[]( string ); glob( string, 0 ); end
		
		def self.foreach( dirname, &block )
			entries( dirname ).each( &block )
		end
		
		def self.glob( string, flags = 0 )
			DirAdapter.new( '/' ).send( :glob, string, flags ).map { |result|
				Path.new( result )#[1..-1]
			}
		end
		
		def self.mkdir( dirname )
			path = Path.new( dirname ).absolute
			node( path.parent ).mkdir( path.node )
		end
		
		def self.rmdir( dirname )
			path = Path.new( dirname ).absolute
			node( path ).delete
		end
		
		attr_reader :path
		
		def initialize( dirname )
			unless node( dirname ).is_a? MockFileSystem::MockDir
				raise Errno::ENOTDIR 
			end
			@path = dirname
		end
		
		def entries; self.class.entries( @path ); end
		
		protected
		
		def glob( string, flags = 0 )
			glob_path = Path.new string
			if glob_path.size > 1
				if glob_path.first != '**'
					subdir = DirAdapter.new( File.join( self.path, glob_path.first ) )
					subdir.send( :glob, glob_path[1..-1], flags )
				else
					if glob_path.size > 2 and glob_path[1] == Path.new( path ).last
						glob( glob_path[2..-1], flags )
					else
						if glob_path.size == 2
							matches = match_entries( glob_path[-1], flags )
						else
							matches = []
						end
						DirAdapter.entries( path ).each do |entry|
							unless %w( . .. ).include? entry
								if FileAdapter.directory? File.join( path, entry )
									subdir = DirAdapter.new File.join( self.path, entry )
									matches << subdir.send( :glob, glob_path, flags )
								end
							end
						end
						matches.flatten.uniq
					end
				end
			else
				match_entries( string, flags )
			end
		end
		
		def match_entries( string, flags )
			string = string.gsub( /\./, '\.' )
			string = string.gsub( /\?/, '.' )
			string = string.gsub( /\*/, ".*" )
			string = string.gsub( /\{(.+),(.+)\}/, '(\1|\2)' )
			re = Regexp.new string
			DirAdapter.entries( path ).select { |entry|
				flags & File::FNM_DOTMATCH != 0 || !%w( . .. ).include?( entry )
			}.select { |entry| entry =~ re }.map { |entry| File.join( path, entry ) }
		end
	end
	
	class FileAdapter #:nodoc:
		extend Adapter
	
		def self.chmod( perms, *filenames )
			node( filenames.first ).permissions = perms
		end
		
		def self.directory?( file_name )
			begin
				node( file_name ).is_a? MockFileSystem::MockDir
			rescue Errno::ENOENT
				false
			end
		end
		
		def self.dirname( file_name )
			File.dirname file_name
		end
		
		def self.stat(file_name)
		  open(file_name).stat
		end
		
		class << self
			def exist?( filename )
				begin
					node( filename )
					true
				rescue Errno::ENOENT
					false
				end
			end
			
			alias_method :exists?, :exist?
		end

		def self.file?( file_name )
			begin
				node( file_name ).is_a? MockFileSystem::MockFile
			rescue Errno::ENOENT
				false
			end
		end
				
		def self.mock_file( fd, mode ) #:nodoc:
			if mode.read_only?
				mock_file = node( fd )
				raise Errno::EACCES if mock_file and !mock_file.readable?
			else
				path = Path.new( fd ).absolute
				dir = node( path.parent )
				if mode.append?
					mock_file = node( fd )
				else
					mock_file = MockFileSystem::MockFile.new( dir, path.node, '' )
				end
			end
			mock_file
		end
		
		def self.open( fd, mode_string = File::RDONLY, &action )
			mode = Mode.new mode_string
			mock_file = mock_file( fd, mode )
			mock_file.pos = mock_file.size if mode.append?
			if !mode.read_only? and !mode.append?
				mock_file.parent[Path.new( fd ).absolute.node] = mock_file
			end
			if action
				result = action.call( mock_file )
				mock_file.rewind
				result
			else
				mock_file
			end
		end
		
		def self.read( name )
			mfile = node name
			raise Errno::EISDIR if mfile.is_a? MockFileSystem::MockDir
			contents = mfile.read
			mfile.rewind
			contents
		end
		
		class Mode #:nodoc:
			def initialize( string_or_bitwise )
				if string_or_bitwise.is_a?( String )
					if string_or_bitwise == 'w'
						@bitwise = File::WRONLY
					elsif string_or_bitwise == 'r'
						@bitwise = File::RDONLY
					elsif string_or_bitwise == 'a'
						@bitwise = File::APPEND
					end
				else
					@bitwise = string_or_bitwise
				end
			end
			
			def append?; @bitwise & File::APPEND == File::APPEND; end
			
			def read_only?; @bitwise == File::RDONLY; end
		end
	end
	
	class FileUtilsAdapter #:nodoc:
		extend Adapter
		
		def self.cp( src, dest, options = {} )
			file = node( src ).clone
			dest_path = Path.new( dest ).absolute
			if MockFS.file.exist?( dest )
				maybe_dest_dir = node dest_path
				if maybe_dest_dir.is_a? MockFileSystem::MockDir
					dest_path << ( '/' + Path.new( src ).absolute.node )
				end
			end
			dest_dir = node dest_path.parent
			dest_dir[dest_path.node] = file
			file.name = dest_path.node
			file.parent = dest_dir
		end
		
		def self.cp_r(src, dest, options = {})
		end
		
		def self.mkpath( path ); MockFS.fill_path( path ); end
		def self.mkdir_p(path); mkpath(path); end
		
		def self.rm_rf(path)
		  # DirAdapter.rmdir does not pay attention to whether or not the director
		  # is empty, so we'll just use that for now.
		  DirAdapter.rmdir(path)
		end
		
		def self.chmod_R(mode, list, options={})
		  # node(list).permissions = mode
		end

		def self.chown_R(user, group, list, options={})
		  # TODO ADD
		end
				
		class << self
			def mv( src, dest, options = {} )
				cp( src, dest, options )
				MockFS.file.delete( src )
			end

			alias_method :move, :mv
		end
		
		def self.touch( file )
			begin
				node( file ).mtime = Time.now
			rescue Errno::ENOENT
				path = Path.new( file ).absolute
				parent_dir = node( path.parent )
				file = MockFileSystem::MockFile.new( parent_dir, path.node, '' )
				parent_dir[path.node] = file
			end
		end
	end
	
	# The MockFileSystem is the singleton class that pretends to be the file 
	# system in mock mode. When it's first created, it fills in the root path; 
	# other paths will have to be filled by hand using +fill_path+.
	class MockFileSystem
		include Singleton
		
		# Flushes all file information out of the MockFileSystem.
		def self.flush; instance.flush; end
		
		def initialize #:nodoc:
			flush
		end
				
		def begin
		  @stored_root = @root.clone
		end
		
		def rollback!
		  @root        = @stored_root
		  @stored_root = nil
		end
		
		def clone_real_directory_under(root, directory)
		  MockFS.fill_path root
		  Dir.entries(directory).each do |e|
		    next if ['.', '..', '.svn'].include?(e)
		    if File.directory? File.join(directory, e)
		      clone_real_directory_under File.join(root, e), File.join(directory, e)
	      else
	        MockFS.file.open(File.join(root, e), 'w') do |f|
	          f.write File.open(File.join(directory, e), 'r').read
          end
        end
	    end
		end
		
		# Flushes all file information out of the MockFileSystem.
		def flush; @root = MockRoot.new( '' ); end
		
		# Use this method to fill in directory paths. This is the same as calling mkdir a bunch of times.
		#
		#   MockFS.mock_file_system.fill_path '/usr/local/bin'
		#   MockFS.mock_file_system.fill_path '/home/francis/Desktop/myproject/'
		def fill_path( dirname )
			@root.fill_path( Path.new( dirname ).absolute.strip )
		end
		
		def node( dirname ) #:nodoc:
			@root.node( dirname )
		end
		
		module Node #:nodoc:
			attr_accessor :mtime, :name, :parent, :permissions
			
			def readable?
				!permissions or permissions[0] != 0
			end
		end
		
		class MockDir < DelegateClass( Hash ) #:nodoc:
			include Node
			
			def initialize( name, parent = nil )
				super( {} )
				@name, @parent = name, parent
				@mtime = Time.now
			end
			
			def clone(parent=nil)
			  new_node = self.class.new(@name, parent)
			  new_node.mtime = @mtime        

        self.each do |k, v|
          new_node[k] = v.clone(new_node)
        end
        
        new_node
			end
			
			def stat
			  OpenStruct.new :gid => 501, :uid => 501
			end

			def []= ( name, child )
				super
				@mtime = child.mtime
			end
			
			def delete( child = nil )
				child ? super( child.name ) : parent.delete( self )
			end
			
			def entries; %w( . .. ).concat( keys ); end
			
			def fill_dir( dirname )
				dir = self[dirname]
				if dir.nil?
					dir = MockDir.new( dirname, self )
					self[dirname] = dir
					@mtime = dir.mtime
				end
				dir
			end
			
			def fill_path( dirname )
				if dirname.size > 1
					if dirname.first != '..'
						dir = fill_dir( dirname.first )
						dir.fill_path( dirname[1..-1] )
					else
						parent.fill_path( dirname[1..-1] )
					end
				else
					fill_dir( dirname )
				end
			end
			
			def mkdir( dirname ); fill_path( Path.new( dirname ) ); end

			def node( dirname )
				if dirname.first == '..'
					self.parent.node( dirname[1..-1] )
				elsif dirname.first == '.'
					self.node( dirname[1..-1] )
				elsif dirname.size > 1
					subdir = self[dirname.first]
					subdir ? subdir.node( dirname[1..-1] ) : ( raise Errno::ENOENT )
				elsif dirname == ''
					self
				else
					self[dirname.strip] or ( raise Errno::ENOENT )
				end
			end

      protected
			def mtime=(mtime)
			  @mtime = mtime
			end      
		end
		
		class MockFile < DelegateClass( StringIO ) #:nodoc:
			include Node
			
			attr_writer :contents
		
			def initialize( parent, name, contents )
				@name = name; @parent = parent; @mtime = Time.now; @contents = contents
				super( StringIO.new( contents ) ) if contents
			end
			
			def clone(parent=nil)
				rewind
				clone = self.class.new( parent || @parent, @name, gets( nil ) )
				rewind
				clone.mtime = @mtime
				clone
			end
			
			def close; rewind; end

			def delete
			  parent.delete( self )
			end
			
			def gets( sep_string = $/ )
				@contents ? super( sep_string ) : nil
			end
			
			def rewind; @contents ? super : nil; end
			
			def stat
			  OpenStruct.new :gid => 501, :uid => 501
			end
		end
		
		class MockRoot < MockDir #:nodoc:
			def node( dirname )
				begin
					super( Path.new( dirname ).absolute.strip )
				rescue Errno::ENOENT
					raise Errno::ENOENT.new( dirname )
				end
			end
		end
	end
	
	class Path < String #:nodoc:
		@@getwd = nil
		
		def self.getwd
			@@getwd = Dir.getwd if @@getwd.nil?
			@@getwd
		end
	
		def []( *args )
			if args.size == 1 and args.first.is_a? Fixnum
				Path.new self.split( "/" )[*args]
			else
				Path.new self.split( "/" )[*args].join( "/" )
			end
		end
	
		def absolute
			if self =~ %r{^\w}
				Path.new( File.join( self.class.getwd, self ) )
			else
				new_str = self.to_s
				new_str.gsub!( %r{^\.\.}, self.class.getwd + '/..' )
				new_str.gsub!( %r{^\.}, self.class.getwd )
				Path.new( new_str )
			end
		end
		
		def first; self.split( "/" ).first; end
	
		def last; self.split( "/" ).last; end

		def node
			self =~ %r{^(.*)/(.*?)$}
			$2
		end
		
		def parent
			self =~ %r{^(.*)/(.*?)$}
			$1
		end
		
		def size; self.split( '/' ).size; end
		
		def strip; self.gsub( %r{^/+}, '' ).gsub( %r{/+$}, '' ); end
	end
end