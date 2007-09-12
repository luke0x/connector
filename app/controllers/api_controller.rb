=begin #(fold)
Copyright 2004-2007 Joyent Inc.

Redistribution and/or modification of this code is governed
by either the GPLv2 or Joyent Commercial Software licenses.

Report issues and contribute at http://dev.joyent.com/

$Id$
=end #(end)

# can't use application_controller
class ApiController < ActionController::Base
  before_filter :require_http_authentication
  cattr_accessor :api_user, :api_password
  @@api_user     = JoyentConfig.api_user
  @@api_password = JoyentConfig.api_password
  #verify :method=>:post, :render=>{:text=>"API only accepts post", :status=>"405 Method Not Allowed"}
  
  def authorize
    raise "Invalid request."                unless params[:connector] && user = params[:connector][:user]
    raise "Email address must be included." unless user[:email]
    raise "Password must be included."      unless user[:sha1_password]

    username, domain_name = user[:email].split('@')
    domain                = Domain.find_by_email_domain(domain_name)
    
    raise "Unknown domain."                 unless domain
    
    if user = domain.authenticate_user(username, user[:sha1_password], true)
      # May want to return the system domain
      render :xml => {:system_email => user.system_email, :full_name => user.full_name}.to_xml(:root => 'user')
    else
      render :xml => "<unauthorized/>"
    end
  rescue
    # Should we log this ?
    render :xml => "<unauthorized/>"
  end
  
  def subdomain_available
    if Domain.find(:first, :conditions => ["system_domain = ? AND email_domain like ?", true, "#{params[:subdomain]}.%"])
      render :xml => {:subdomain_available => false}.to_xml
    else
      render :xml => {:subdomain_available => true}.to_xml
    end                                                     
  end
  
  def subdomain_list
    domains = Domain.find(:all, :conditions => ["system_domain = ?", true], :select => :email_domain)
    respond_to do |wants|
      wants.xml do
        subdomain_list = domains.collect{|domain| domain.email_domain.split('.')[0]}.join(",")
        render :xml => {:subdomains => subdomain_list}.to_xml(:root => "taken_subdomains")
      end
    end
  end
  
  def create_organization 
    # TODO: This needs some validation for proper XML if organization isn't present...it's a no go
    o = params[:organization]
    # Verify that the domain does not already exist, if it does, return it 
    unless org = Domain.find_by_email_domain(o[:system_domain])
      name           = o[:name]
      system_domain  = o[:system_domain]
      affiliate      = o[:affiliate] || Affiliate.find(1).name
      username       = o[:user][:username]
      password       = o[:user][:password]
      first_name     = o[:user][:first_name]
      last_name      = o[:user][:last_name]
      recovery_email = o[:user][:recovery_email]
      users          = o[:quota][:users]
      megabytes      = o[:quota][:megabytes]
      custom_domains = o[:quota][:custom_domains]
      org = Organization.setup(name, system_domain, username, password, affiliate, first_name, last_name, recovery_email, users, megabytes, custom_domains)
    end
    render :xml=>org.to_xml
  end
  
  def show_organization
    # NEED TO IMPLEMENT THIS -- usage, domains, etc  
  end
  
  def organization_dispatch
    case request.method
    when :get    then show_organization
    when :put    then update_organization
    when :delete then destroy_organization
    end
  end
  
  def update_organization
    organization = Organization.find(params[:id])
    organization.quota.update_attributes(params[:organization].delete(:quota))
    organization.attributes= params[:organization]
    organization.save!
    render :xml=>organization.to_xml
  end
  
  def domain_dispatch
    case request.method
    when :put    then update_domain
    when :delete then destroy_domain
    end
  end
  
  def destroy_organization
    JoyentJob::Job.new(Organization, params[:id], :destroy).submit
    render :nothing=>true
  end
  
  def lock_organization
    o = Organization.find(params[:id])
    o.active=false
    o.save!
    render :nothing=>true
  end
  
  def unlock_organization
    o = Organization.find(params[:id])
    o.active=true
    o.save!
    render :nothing=>true
  end
  
  def create_domain
    o = Organization.find(params[:id])
    h = params[:domain]
    make_primary = h.delete(:primary) == "true"
    Domain.transaction do
      domain = o.domains.create(h)
      if make_primary
        domain.make_primary!
      end
      render :xml=>domain.to_xml
    end
  end
  
  def update_domain
    o = Organization.find(params[:id])
    h = params[:domain]
    make_primary = h.delete(:primary) == "true"
    Domain.transaction do
      domain = o.domains.find(params[:domain_id])
      if make_primary
        domain.make_primary!
      end
      domain.update_attributes h
      render :xml=>domain.to_xml
    end
  end
  
  def destroy_domain
    o = Organization.find(params[:id])
    d = o.domains.find(params[:domain_id])
    Domain.transaction do 
      if d.system_domain?
        raise "No Way"
      elsif d.primary?
        o.system_domain.make_primary!
      end
      d.destroy
      render :nothing=>true
    end
  end
  
  def authorize_ssh_user
    raise "Invalid request."            unless req_params = params[:organization]
    raise "Orgnization does not exist." unless o = Organization.find(req_params[:id])
    raise "Domain does not exist."      unless d = o.system_domain
    raise "Invalid user credentials."   unless u = d.authenticate_user(req_params[:username], req_params[:password])
    
    u.add_ssh_public_key(req_params[:public_key])
    
    render :xml => {:public_key => o.ssh_public_key, :username => u.system_email, :domain => JoyentConfig.strongspace_domain}.to_xml(:root => :organization)
  rescue RuntimeError => err
    render :xml => {:message => err.message}.to_xml(:root => "error")
  rescue
    render :xml => {:message => "An unknown error has occurred.  Please contact customer support."}.to_xml(:root => "error")
  end
  
  def deauthorize_ssh_user
    raise "Invalid request."            unless req_params = params[:organization]
    raise "Orgnization does not exist." unless o = Organization.find(req_params[:id])
    raise "Domain does not exist."      unless d = o.system_domain
    raise "Invalid user credentials."   unless u = d.authenticate_user(req_params[:username], req_params[:password])

    u.remove_ssh_public_key(req_params[:public_key])

    render :xml => {}.to_xml(:root => :success)
  rescue RuntimeError => err
    render :xml => {:message => err.message}.to_xml(:root => "error")
  rescue
    render :xml => {:message => "An unknown error has occurred.  Please contact customer support."}.to_xml(:root => "error")
  end
  
  # ---------------------------------------------------------------------------

  private
  
    def require_http_authentication
      unless (auth = (request.env['X-HTTP_AUTHORIZATION'] || request.env['HTTP_AUTHORIZATION'])).nil?
        auth = auth.split
        user, password = Base64.decode64(auth[1]).split(':')[0..1]
        if user == @@api_user and password == @@api_password
          return true
        end
      end
      response.headers["Status"] = "Unauthorized"
      response.headers["WWW-Authenticate"] = "Basic realm=\"Feeds and Calendars from Joyent\""
      render :text => 'You must log in to access your RSS/ICS', :status => 401
      false
    end
  
    def rescue_action_in_public(e)
      render :xml=>"<error>#{e}</error>", :status=>500
    end
end