=begin #(fold)
++
Copyright 2004-2007 Joyent Inc.

Redistribution and/or modification of this code is 
governed by the GPLv2.

Report issues and contribute at http://dev.joyent.com/

$Id$
--
=end #(end)

require 'fileutils'

namespace 'joyent' do
  
  desc 'Refresh storage_root test fixtures'
  task :refresh_files do
    dests  = [File.join(RAILS_ROOT, "tmp", "development"),
              File.join(RAILS_ROOT, "tmp", "test")]
    fixture_source           = File.join(RAILS_ROOT, "test", "fixtures", "storage_root")
    dests.each do |d|
      FileUtils.rm_rf(d)
      FileUtils.mkdir_p(d)
      FileUtils.cp_r(fixture_source, d)
    end
  end
  
  task :bootstrap_ldap do 
    puts "Initializing ldap"
    RAILS_ENV = 'production'
    require "#{RAILS_ROOT}/config/environment"
    sh %{cat #{RAILS_ROOT}/config/openldap/joyent.ldif | ldapadd -c -D #{JoyentConfig.admin_dn} -w #{JoyentConfig.ldap_password}}
  end 
  
  desc "build the gmime based mime parser"
  task :gmime do
    puts "Building gmime filter"
    sh "cd vendor/mime_filter/gmime && PATH=$PATH:/opt/joyent/applications/bin PKG_CONFIG_PATH=/usr/local/lib/pkgconfig:/opt/joyent/applications/lib/pkgconfig make"
  end
  
  desc "Concatenate css + js assets into 'all' files"
  task :cat_assets do
    css_assets = %w(item tools apps forms sidebars browser drawers icons master lightbox)
    css_assets = css_assets.collect{|x| "public/stylesheets/#{x}.css"}.join(' ')
    sh %{ cat #{css_assets} > public/stylesheets/all.css }
    puts "\nGenerated all.css from common stylesheets\n\n"

    js_assets = %w(prototype builder effects dragdrop controls joyent_prototype jsar lightbox application ui_elements sidebar browser toolbar group smart_group)
    js_assets = js_assets.collect{|x| "public/javascripts/#{x}.js"}.join(' ')
    sh %{ cat #{js_assets} > public/javascripts/all.js }
    puts "\nGenerated all.js from common javascripts\n\n"
  end
  
  desc "Refresh the JOYENT_MAILDIR/joyent.joyent.com directory contents"
  task :refresh_mail_dir do
    require "#{RAILS_ROOT}/override_config"
    dests = [ENV['JOYENT_MAILDIR']]
    fixture_source = File.join(RAILS_ROOT, "test", "fixtures", "mail_root")
    FileUtils.rm_rf(File.join(dests, "joyent.joyent.com"))
    `svn export #{fixture_source} #{dests} --force`
  end
end
Rake::Task[:test].enhance(['joyent:refresh_files'])
