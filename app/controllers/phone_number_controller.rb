=begin #(fold)
Copyright 2004-2007 Joyent Inc.

Redistribution and/or modification of this code is governed
by either the GPLv2 or Joyent Commercial Software licenses.

Report issues and contribute at http://dev.joyent.com/

$Id: people_controller.rb 168 2007-07-04 21:36:24Z jason@joyent.com $
=end #(end)

class PhoneNumberController < AuthenticatedController
  def manage_sms
    render :partial => 'manage_sms'
  end
end
