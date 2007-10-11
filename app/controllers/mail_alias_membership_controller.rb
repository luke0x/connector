=begin #(fold)
++
Copyright 2004-2007 Joyent Inc.

Redistribution and/or modification of this code is 
governed by the GPLv2.

Report issues and contribute at http://dev.joyent.com/

$Id$
--
=end #(end)

class MailAliasMembershipController < AuthenticatedController
  layout nil

  def index
    @mail_alias = MailAlias.find_by_id(params[:mail_alias_id])
    @mail_aliases = Organization.current.mail_aliases
    unless User.current.admin?
      @mail_aliases = @mail_aliases.select{|ma| ma.membership_for_user(User.current)}
    end

    render :partial => 'mail_alias/mail_aliases'
  end
  
  def create
    return unless User.current.admin?
    @mail_alias = Organization.current.mail_aliases.find_by_id(params[:mail_alias_id])
    @user = Organization.current.users.find_by_id(params[:user_id])
    return unless @mail_alias
    return unless @user
    
    @mail_alias.add_user(@user)
    @mail_aliases = Organization.current.mail_aliases

    respond_to do |wants|
      wants.html { render :nothing => true }
      wants.js   { render :partial => 'mail_alias/mail_aliases' }
    end
  end
  
  def delete
    @mail_alias = Organization.current.mail_aliases.find_by_id(params[:mail_alias_id])
    @user = Organization.current.users.find_by_id(params[:user_id])
    return unless @mail_alias
    return unless @user
    return unless User.current.admin? or User.current.mail_aliases.include?(@mail_alias)

    @mail_alias_membership = @mail_alias.membership_for_user(@user)
    @mail_alias_membership.destroy

    Organization.current.reload
    @mail_aliases = Organization.current.mail_aliases
    unless User.current.admin?
      @mail_aliases = @mail_aliases.select{|ma| ma.membership_for_user(User.current)}
    end
    @mail_alias = @mail_aliases.first

    respond_to do |wants|
      wants.html { render :nothing => true }
      wants.js   { render :partial => 'mail_alias/mail_aliases' }
    end
  end
  
end