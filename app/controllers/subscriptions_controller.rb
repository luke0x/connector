=begin #(fold)
++
Copyright 2004-2007 Joyent Inc.

Redistribution and/or modification of this code is 
governed by the GPLv2.

Report issues and contribute at http://dev.joyent.com/

$Id$
--
=end #(end)

class SubscriptionsController < AuthenticatedController

  def subscribe
    subscription_params = params.reject {|k,v| k == 'action' || k == 'controller'}
    Subscription.create(subscription_params)
    
    render :nothing => true
  end

  def unsubscribe
    Subscription.delete(params[:subscription_id]) if request.post?
    
    respond_to do |wants|
      wants.html { redirect_back_or_home }
      wants.js   { render :nothing => true }
    end
  end

end
