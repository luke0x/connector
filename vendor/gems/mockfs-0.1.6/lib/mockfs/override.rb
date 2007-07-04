# Include this file to redefine FileUtils, Dir, and File. The point of this is so that you can use MockFS to test a codebase that calls these classes directly instead of going through MockFS.file_utils, etc.
#
# Please note that as of this writing (June 11, 2006), this file is still fairly experimental. Please exercise caution when relying on tests through this.

require 'mockfs'

MockFS.mock = true

MockFS::OriginalFileUtils = FileUtils
Object.send( :remove_const, :FileUtils )
module FileUtils #:nodoc:
	def self.method_missing( symbol, *args, &action )
		file_utils = MockFS.mock? ? MockFS.file_utils : MockFS::OriginalFileUtils
		file_utils.send( symbol, *args, &action )
	end
end

getwd = Dir.getwd
MockFS::OriginalDir = Dir
Object.send( :remove_const, :Dir )
module Dir #:nodoc:
	def self.method_missing( symbol, *args, &action )
		dir = MockFS.mock? ? MockFS.dir : MockFS::OriginalDir
		dir.send( symbol, *args, &action )
	end
end
Dir.module_eval "def self.getwd; '#{ getwd }'; end"

$join_method = File.method :join
$dirname_method = File.method :dirname
$file_constants = {}
File.constants.map do |const_str|
	$file_constants[const_str] = File.const_get const_str.to_sym
end
MockFS::OriginalFile = File
Object.send( :remove_const, :File )
module File #:nodoc:
	$file_constants.each do |const_str, const_val|
		self.const_set( const_str, const_val )
	end
	
	def self.dirname( *args ); $dirname_method.call( *args ); end
	
	def self.join( *args )
		$join_method.call *args
	end

	def self.method_missing( symbol, *args, &action )
		file = MockFS.mock? ? MockFS.file : MockFS::OriginalFile
		file.send( symbol, *args, &action )
	end
end

$orig_require = Kernel.method :require

# mockfs/override.rb overrides Kernel.require to allow you to include Ruby files that are in the mock file system:
#
#   require 'mockfs/override'
#   MockFS.file.open( 'virtual.rb', 'w' ) do |f|
#     f.puts "puts 'I am a ruby program living in a virtual file'"
#   end
#   require 'virtual.rb'
#   require 'rexml'        # real files are still accessible
def require( library_name )
	begin
		MockFS.mock = false
		super
		MockFS.mock = true
	rescue LoadError => err
		MockFS.mock = true
		file = library_name
		file += '.rb' unless library_name =~ /\.rb$/
		if File.exist? file
			contents = File.open( file ) do |f| f.gets( nil ); end
			eval contents
		else
			raise
		end
	end
end
