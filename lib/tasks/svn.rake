=begin #(fold)
++
Copyright 2004-2007 Joyent Inc.

Redistribution and/or modification of this code is 
governed by the GPLv2.

Report issues and contribute at http://dev.joyent.com/

$Id$
--
=end #(end)

namespace 'svn' do
  
  desc 'Update code from Subversion'
  task :up do
    puts 'Latest logs from Subversion...'
    sh %{svn log -r BASE:HEAD}
    puts 'Updating from Subversion...'
    sh %{svn up}
  end
  
  desc 'Update code from Subversion, run migrations, and reload fixtures'
  task :up! => :up do
    puts 'Migrating database...'
    Rake::Task['db:migrate'].invoke
    puts 'Loading fixtures...'
    Rake::Task['db:fixtures:load'].invoke
    puts 'Creating files sandbox'
    Rake::Task['joyent:refresh_files'].invoke
  end

end