set :user, 'joyent'
set :group, 'staff'
# This is the public IP address provided with the Accelerator passwords
# You may try by running this at the command line, after you checked 
# that have ggrep installed into the Accelerator: 
# (This is for VirtualMachine at home)
set :getip, "ifconfig -a | ggrep -A1 pcn0 | grep inet | awk '{print $2}'"

set :domain, 'connector.solarisdevbox' 
 
role :app, domain
role :web, domain
role :db,  domain, :primary => true

set :server_name, "connector.solarisdevbox"
set :server_alias, "*.connector.solarisdevbox"

ssh_options[:paranoid] = false
# cap 2.1 `sudo -p` switch bothers me if I haven't got another ssh session 
# into the same server and I've `sudo -s` there, and the next option
# is configured as follow:
default_run_options[:pty] = true