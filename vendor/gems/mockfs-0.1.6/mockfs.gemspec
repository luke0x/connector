require 'rubygems'
spec = Gem::Specification.new do |s|
	s.add_dependency( 'extensions' )
	s.name = 'mockfs'
	s.version = '0.1.6'
	s.platform = Gem::Platform::RUBY
	s.date = Time.now
	s.summary = "MockFS is a test-obsessed library for mocking out the entire file system."
	s.description = <<-DESC
MockFS is a test-obsessed library for mocking out the entire file system. It provides mock objects that clone the functionality of File, FileUtils, Dir, and other in-Ruby file-access libraries.
	DESC
	s.require_paths = [ 'lib' ]
	s.files = Dir.glob( 'lib/**/*' ).delete_if { |item|
		item.include?('CVS')
	}
	s.author = "Francis Hwang"
	s.email = 'sera@fhwang.net'
	s.homepage = 'http://mockfs.rubyforge.org/'
	s.autorequire = 'mockfs'
	s.has_rdoc = true
	s.rdoc_options << '--main' << 'lib/mockfs.rb'
end
if $0==__FILE__
  Gem::Builder.new(spec).build
end
