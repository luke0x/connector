=begin #(fold)
Copyright 2004-2007 Joyent Inc.

Redistribution and/or modification of this code is governed
by either the GPLv2 or Joyent Commercial Software licenses.

Report issues and contribute at http://dev.joyent.com/

$Id$
=end #(end)

class DeveloperToolsController < AuthenticatedController

  before_filter :ensure_development_mode

  def set_organization
  ensure
    redirect_back_or_home
  end
  
  def set_user
    # return unless params.has_key?(:user_id)
    # return unless u = User.find(params[:user_id])
    # session[:user_id] = u.id
    # User.current = u
    # self.selected_user = u
  ensure
    redirect_back_or_home
  end
  
  def set_language
  ensure
    redirect_back_or_home
  end
  
  private

    def ensure_development_mode
      return false unless RAILS_ENV == 'development'
    end

end