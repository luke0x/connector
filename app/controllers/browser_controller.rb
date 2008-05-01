=begin #(fold)
++
Copyright 2004-2007 Joyent Inc.

Redistribution and/or modification of this code is 
governed by the GPLv2.

Report issues and contribute at http://dev.joyent.com/

$Id$
--
=end #(end)

class BrowserController < AuthenticatedController
  
  layout false
  
  # Here is the breakdown of how a browser is rendered:
  # /browser/list?context=subscribe&app=Files is called directly or via AJAX
  # if app is left out, it will display a choice of apps
  # if context is subscribe it will display org-users
  #
  # render path: 
  #   browser#list: _list.rhtml (outer wrapper) - application_helper#render_initial_column - 
  #     _columns.rhtml (which is recursive, every item link calls browser#column, partial displays items in column)
  #       remote_link in _columns.rhtml calls browser#column - column.rjs - _columns.rhtml
  
  def list
    session[:browser_context] = params[:context] #expects context param
    case session[:browser_context]
    when 'move', 'copy', 'add'
      params[:type] == 'group'
      params[:user_id] == current_user
    end
    render :partial => 'list', :locals => {:params => params}
  end
  
  def column
    browsable = Browsable.new(params, current_user)
    @items = browsable.items
  end
  
end
