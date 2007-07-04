require 'test/unit'

namespace :sbdd do
  desc 'Dump a report of simply bdd contexts/specs'
  task :report => [:units] do
    puts
    puts open('/tmp/sbddreport', 'r').read
    puts
    File.unlink('/tmp/sbddreport') rescue nil
  end
  
  Rake::TestTask.new(:units) do |t|
    File.unlink('/tmp/sbddreport') rescue nil

    t.libs << "test"
    t.pattern = 'test/unit/**/*_test.rb'
    t.test_files = File.dirname(__FILE__) + '/kill_test_unit.rb'
    t.verbose = true
    
  end
end