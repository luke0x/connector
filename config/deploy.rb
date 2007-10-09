=begin #(fold)
++
Copyright 2004-2007 Joyent Inc.

Redistribution and/or modification of this code is 
governed by the GPLv2.

Report issues and contribute at http://dev.joyent.com/

$Id$
--
=end #(end)

require 'mongrel_cluster/recipes'   

# SOME THINGS I HAD TO DO TO GET THINGS STARTED ON A NEW ZONE:
# * checked out from svn then removed it (as to get my password on there)
# * change /etc/passwd so that /bin/bash is the default shell
# * added "PermitUserEnvironment yes" to /etc/ssh/sshd_config
# * svcadm restart ssh
# * created /.ssh/environment
#  -- PATH=/opt/csw/bin:/usr/bin:/usr/sbin
#
# cap setup
# 
# * Make any changes to the files in shared
# * create db                             
# 
# cap deploy
#                                      
# COMMANDS I HAVE CHECKED OUT                                              
# cap <command>
# commands: setup, start, stop, restart, deploy, rollback, deploy_with_migrations

# =============================================================================
# REQUIRED VARIABLES
# =============================================================================
set :application, "connector"
set :repository, "http://svn.joyent.com/joyent/connector-merge"

role :web, "webhostname"
role :app, "apphostname"
role :db,  "dbhostname", :primary => true

#set :rails_env, :development


# =============================================================================
# OPTIONAL VARIABLES
# =============================================================================
set :deploy_to, "/opt/joyent/#{application}"
set :mongrel_conf, "#{current_path}/config/mongrel_cluster.yml"

set :user, "root"
set :svn, "/opt/csw/bin/svn"
set :sudo, "/opt/csw/bin/sudo"       

                            
# =============================================================================
# TASKS
# ============================================================================= 
task :after_setup do                                                                  
  put (File.read('lib/joyent_config.rb'),              "#{shared_path}/joyent_config.rb", :mode => 0644)
  put (File.read('config/database.yml'),               "#{shared_path}/database.yml",     :mode => 0644)
  put (File.read('config/environments/production.rb'), "#{shared_path}/production.rb",    :mode => 0644)  
end

task :after_update_code do 
  run "rm #{release_path}/lib/joyent_config.rb"
  run "cp #{shared_path}/joyent_config.rb #{release_path}/lib/joyent_config.rb"  
  
  # Copy in the database.yml file
  run "rm #{release_path}/config/database.yml"
  run "cp #{shared_path}/database.yml #{release_path}/config/database.yml"    
  
  # Copy in a stubbed out production
  run "rm #{release_path}/config/environments/production.rb"
  run "cp #{shared_path}/production.rb #{release_path}/config/environments/production.rb"
end

task :before_symlink do
  run "if [[ -d #{current_path} ]]; then rm #{current_path}; fi"
end     

task :start_mongrel_cluster , :roles => :app do
  set_mongrel_conf
  run "cd #{current_path}; mongrel_rails cluster::start -C #{mongrel_conf}"
end                                     

task :stop_mongrel_cluster , :roles => :app do
  set_mongrel_conf
  run "cd #{current_path}; mongrel_rails cluster::stop -C #{mongrel_conf}"
end    

task :restart, :roles => :app do
  stop
  start
end

task :stop, :roles => :app do
  stop_mongrel_cluster
  stop_imap_worker
  stop_joyent_job  
end

task :start, :roles => :app do 
  start_mongrel_cluster
  start_imap_worker
  start_joyent_job
end

task :start_imap_worker, :roles => :app do
  run <<-CMD
    export RAILS_ENV=#{rails_env}; 
    nohup #{current_path}/script/imap_worker start; 
    sleep 5
  CMD
end
   
task :stop_imap_worker, :roles => :app do
  run <<-CMD
    export RAILS_ENV=#{rails_env}; 
    #{current_path}/script/imap_worker stop; 
    sleep 1
  CMD
end        

task :start_joyent_job, :roles => :app do
  run <<-CMD
    export RAILS_ENV=#{rails_env}; 
    nohup ruby #{current_path}/script/joyent_job start; 
    sleep 5;
    export RAILS_ENV=#{rails_env}; 
    nohup ruby #{current_path}/script/joyent_job start_worker 5; 
    sleep 5
  CMD
end

task :stop_joyent_job, :roles => :app do
  run "ruby #{current_path}/script/joyent_job stop"    
end
                           
task :before_rollback_code, :except => { :no_release => true } do
  if releases.length < 2
    raise "could not rollback the code because there is no prior release"
  else
    run "rm #{current_path}"
  end
end
