=begin #(fold)
Copyright 2004-2007 Joyent Inc.

Redistribution and/or modification of this code is governed
by either the GPLv2 or Joyent Commercial Software licenses.

Report issues and contribute at http://dev.joyent.com/

$Id$
=end #(end)

class ListCellsController < AuthenticatedController

  helper :lists

  # PUT /list_cells/1
  # PUT /list_cells/1.xml
  def update
    @list_cell = ListCell.find(params[:id])
    @list = List.find(@list_cell.list.id, :include => [:list_columns, {:list_rows => [:list_cells]}], :scope => :edit)

    update_params = {:value => (params[:value] || '').chars.strip.to_s}

    respond_to do |format|
      if @list_cell.update_attributes(update_params)
        format.js  { 
          if @list_cell.kind == 'Number'
            if @list_cell.ancestors.any?{|lc| lc.value == '+'}
              render(:update) {|page| page.replace_html 'listContainer', :partial => 'lists/list' }
            else
              render :text => @list_cell.view_value
            end
          else
            render :text => @list_cell.view_value
          end
        }
        format.xml { head :ok }
      else
        format.js  { render :text => @list_cell.view_value }
        format.xml { render :xml => @list_cell.errors.to_xml }
      end
    end
  end

  private

    def load_application
      @application_name = 'lists'
    end

end