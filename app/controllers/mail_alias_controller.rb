=begin #(fold)
++
Copyright 2004-2007 Joyent Inc.

Redistribution and/or modification of this code is 
governed by the GPLv2.

Report issues and contribute at http://dev.joyent.com/

$Id$
--
=end #(end)

class MailAliasController < AuthenticatedController
  layout nil

  def index
    @mail_aliases = current_organization.mail_aliases
    unless current_user.admin?
      @mail_aliases = @mail_aliases.select{|ma| ma.membership_for_user(current_user)}
    end
    @mail_alias = @mail_aliases.first
    
    render :partial => 'mail_aliases'
  end
  
  def create
    return unless current_user.admin?
    return if params[:name].blank?
    return if current_organization.mail_aliases.find_by_name(params[:name])

    @mail_alias = current_organization.mail_aliases.create(:name => params[:name])
    current_organization.mail_aliases.reload
    @mail_aliases = current_organization.mail_aliases

    render :partial => 'mail_aliases'
  end
  
  def delete
    return unless current_user.admin?
    
    mail_alias = current_organization.mail_aliases.find_by_id(params[:id])
    mail_alias.destroy
    
    @mail_aliases = current_organization.mail_aliases
    @mail_alias = @mail_aliases.first

    render :partial => 'mail_aliases'
  end
end