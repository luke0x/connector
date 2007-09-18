=begin #(fold)
Copyright 2004-2007 Joyent Inc.

Redistribution and/or modification of this code is governed
by either the GPLv2 or Joyent Commercial Software licenses.

Report issues and contribute at http://dev.joyent.com/

$Id$
=end #(end)

class GuestController < AuthenticatedController
  layout nil

  helper :people

  # should only work for a guest to edit himself
  def edit
    @person = current_user.person
    
    if request.post?
      if @person.update_guest_from_params(params[:person])
        flash[:message] = "Your account settings were updated."
      else
        flash[:error] = "An error occured saving your account settings."
      end

      redirect_to files_strongspace_url
    end
  end

  private

    def verify_app_enabled
      current_user.guest?
    end
end