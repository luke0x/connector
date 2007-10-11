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
    @mail_aliases = Organization.current.mail_aliases
    unless User.current.admin?
      @mail_aliases = @mail_aliases.select{|ma| ma.membership_for_user(User.current)}
    end
    @mail_alias = @mail_aliases.first
    
    render :partial => 'mail_aliases'
  end
  
  def create
    return unless User.current.admin?
    return if params[:name].blank?
    return if Organization.current.mail_aliases.find_by_name(params[:name])

    @mail_alias = Organization.current.mail_aliases.create(:name => params[:name])
    Organization.current.mail_aliases.reload
    @mail_aliases = Organization.current.mail_aliases

    render :partial => 'mail_aliases'
  end
  
  def delete
    return unless User.current.admin?
    
    mail_alias = Organization.current.mail_aliases.find_by_id(params[:id])
    mail_alias.destroy
    
    @mail_aliases = Organization.current.mail_aliases
    @mail_alias = @mail_aliases.first

    render :partial => 'mail_aliases'
  end
end