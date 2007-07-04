=begin #(fold)
Copyright 2004-2007 Joyent Inc.

Redistribution and/or modification of this code is governed
by either the GPLv2 or Joyent Commercial Software licenses.

Report issues and contribute at http://dev.joyent.com/

$Id$
=end #(end)

class ListColumnsController < AuthenticatedController

  helper :lists

  def create
    @list = List.find(params[:list_id], :include => [:list_columns, {:list_rows => [:list_cells]}], :scope => :edit)
    @list_column = @list.list_columns.build(:name => _('New Column'), :kind => 'Text')

    respond_to do |format|
      if @list_column.save
        format.js  { render(:update) { |page|
          page.replace_html 'listContainer', :partial => 'lists/list'
          page.call 'List.fadeUp', 'listContainer'
          page.replace 'temp_column', :partial => 'lists/list_column'
        } }
        format.xml { head :created, :location => list_column_url(@list_column) }
      else
        format.js  { render :nothing => true }
        format.xml { render :xml => @list_column.errors.to_xml }
      end
    end
  end

  def update
    @list_column = ListColumn.find(params[:id])
    @list = @list_column.list

    respond_to do |format|
      if User.current.can_edit?(@list) and @list_column.update_attributes(params[:list_column])
        format.js  { render :partial => 'lists/list' }
        format.xml  { head :ok }
      else
        format.js  { render :nothing => true }
        format.xml { render :xml => @list_column.errors.to_xml }
      end
    end
  end

  def destroy
    @list_column = ListColumn.find(params[:id])
    @list = @list_column.list
    if User.current.can_edit?(@list)
      @list_column.destroy
    end

    if @list_column.frozen? # destroy worked
      respond_to do |format|
        format.js { render(:update) { |page|
          page.remove "column_#{@list_column.id}"
          page.replace_html 'listContainer', :partial => 'lists/list'
          page.call 'List.fadeUp', 'listContainer'
        } }
        format.xml { head :ok }
      end
    else
      respond_to do |format|
        format.js { render(:update) { |page|
          page.alert(_('There was an error deleting the column.'))
        } }
        format.xml { @list_column.errors.to_xml }
      end
    end
  end
  
  def reorder
    @list = List.find(params[:id], :include => [:list_columns, {:list_rows => [:list_cells]}], :scope => :edit)
    
    return unless params.has_key?(:list_columns)
    return unless params[:list_columns].length == @list.list_columns.length
    
    params[:list_columns].each_with_index do |list_column_id, i|
      @list.list_columns.update(list_column_id, :position => i + 1)
    end
    @list.list_columns.reload

    respond_to do |format|
      format.js { render(:update) { |page|
        page.replace_html 'listContainer', :partial => 'lists/list'
        page.replace_html 'drawerEdit', :partial => 'lists/edit'
      } }
    end
  end

  private

    def load_application
      @application_name = 'lists'
    end

end
