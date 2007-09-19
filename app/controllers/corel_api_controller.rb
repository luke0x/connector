class CorelApiController < ActionController::Base
  session :off
  before_filter :load_user
  before_filter :auth_user, :except => [:reset_password]
  
  def reset_password
    return fail_hard unless @user.recovery_email == params[:email]
    @user.auto_generate_password!
    render :text => ''
  end
  
  def update_password
    unless @user.update_password params[:new_password], params[:new_password]
      render :text => '16', :status => 400
      return
    end
    @user.save
    render :text => ''
  end
  
  def set_language
    if params[:language].blank?
      render :text => '4096', :status => 400
      return
    end
    
    @user.set_option 'Language', params[:language]
    render :text => ''
  end
  
  def user_info
  end
  
  def key
    key = AuthKey.generate(@org, @user, params[:password])
    
    headers['Content-Type'] = 'text/plain'
    render :text => key.key
  rescue
    fail_hard 'Invalid username or password.'
  end
  
  private
  def load_user
    return fail_hard unless dom = Domain.find_by_web_domain(request.host)
    
    return fail_hard unless @org = dom.organization
        
    return fail_hard unless @user = @org.users.find_by_username(params[:username])

    Organization.current = @org # Needed by SystemMailer
  end
  
  def auth_user
    return fail_hard unless @user.authenticate(params[:password] || params[:old_password])
  end
  
  def fail_hard(with='')
    response.headers["Status"] = "Unauthorized"
    response.headers["WWW-Authenticate"] = "Basic realm=\"Auth Key API\""
    render :text => with, :status => 401
    false
  end
end
