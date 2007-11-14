# We have to config this properly!!

set :user, 'foo'

# Connector stagging servers
# Give a look to deploy/testing.rb

# This is the public IP address provided with the Accelerator passwords
# You may try by running this at the command line, after you checked 
# that have ggrep installed into the Accelerator:
set :getip, "ifconfig -a | ggrep -A1 e1000g0 | grep inet | awk '{print $2}'"

set :domain, 'domain.com' 
 
role :app, domain
role :web, domain
role :db,  domain, :primary => true

set :server_name, "domain.com"