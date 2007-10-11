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
    @mail_aliases = current_organization.mail_aliases
    unless current_user.admin?
      @mail_aliases = @mail_aliases.select{|ma| ma.membership_for_user(current_user)}
    end

    render :partial => 'mail_alias/mail_aliases'
  end
  
  def create
    return unless current_user.admin?
    @mail_alias = current_organization.mail_aliases.find_by_id(params[:mail_alias_id])
    @user = current_organization.users.find_by_id(params[:user_id])
    return unless @mail_alias
    return unless @user
    
    @mail_alias.add_user(@user)
    @mail_aliases = current_organization.mail_aliases

    respond_to do |wants|
      wants.html { render :nothing => true }
      wants.js   { render :partial => 'mail_alias/mail_aliases' }
    end
  end
  
  def delete
    @mail_alias = current_organization.mail_aliases.find_by_id(params[:mail_alias_id])
    @user = current_organization.users.find_by_id(params[:user_id])
    return unless @mail_alias
    return unless @user
    return unless current_user.admin? or current_user.mail_aliases.include?(@mail_alias)

    @mail_alias_membership = @mail_alias.membership_for_user(@user)
    @mail_alias_membership.destroy

    current_organization.reload
    @mail_aliases = current_organization.mail_aliases
    unless current_user.admin?
      @mail_aliases = @mail_aliases.select{|ma| ma.membership_for_user(current_user)}
    end
    @mail_alias = @mail_aliases.first

    respond_to do |wants|
      wants.html { render :nothing => true }
      wants.js   { render :partial => 'mail_alias/mail_aliases' }
    end
  end
  
end