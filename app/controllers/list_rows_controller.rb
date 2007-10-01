=begin #(fold)
Copyright 2004-2007 Joyent Inc.

Redistribution and/or modification of this code is governed
by either the GPLv2 or Joyent Commercial Software licenses.

Report issues and contribute at http://dev.joyent.com/

$Id$
=end #(end)

class ListRowsController < AuthenticatedController
  
  helper :lists
  
  def create
    @list = List.find(params[:list_id], :include => [:list_columns, {:list_rows => [:list_cells]}], :scope => :edit)
    List.current = @list
    @selected_list_row = @list.list_rows.detect{|lr| lr.id == params[:selected_list_row_id].to_i}
    @list_row = @list.create_row(@selected_list_row)
    @selected_list_row = @list_row

    respond_to do |format|
      if ! @list_row.new_record?
        format.js  { render :partial => 'lists/list', :locals => {:new_row => @list_row} }
        format.xml { head :created, :location => list_row_url(@list_row) }
      else
        format.js do
          @list = List.find(params[:list_id], :include => [:list_columns, {:list_rows => [:list_cells]}], :scope => :edit)
          render(:update) {|page| page.replace_html 'listContainer', :partial => 'lists/list', :locals => {:new_row => @list_row}}
        end
        format.xml { render :xml => @list_row.errors.to_xml }
      end
    end
  end

  def destroy
    @list_row = ListRow.find(params[:id])
    @list = @list_row.list
    if @list and current_user.can_edit?(@list)
      @list_row.destroy
    end

    respond_to do |format|
      format.js  { render :nothing => true }
      format.xml { head :ok }
    end
  end

  def expand
    @list_row = ListRow.find(params[:id])
    @list = @list_row.list
    if @list and current_user.can_edit?(@list)
      @list_row.expand!
    end

    respond_to do |format|
      format.js  { render :nothing => true }
      format.xml { head :ok }
    end
  end
  
  def collapse
    @list_row = ListRow.find(params[:id])
    @list = @list_row.list
    if @list and current_user.can_edit?(@list)
      @list_row.collapse!
    end

    respond_to do |format|
      format.js  { render :nothing => true }
      format.xml { head :ok }
    end
  end

  def indent
    @list_row = ListRow.find(params[:id])
    @selected_list_row = @list_row
    @list = List.find(@list_row.list_id, :scope => :edit) # to check editability
    @list_row.indent!
    @list = List.find(@list_row.list_id, :include => [:list_columns, {:list_rows => [:list_cells]}], :scope => :edit) # to render

    respond_to do |format|
      format.js  { render(:update) {|page| page.replace_html 'listContainer', :partial => 'lists/list' } }
      format.xml { head :ok }
    end
  end
  
  def up
    @list_row = ListRow.find(params[:id])
    @selected_list_row = @list_row
    @list = List.find(@list_row.list_id, :include => [:list_columns, {:list_rows => [:list_cells]}], :scope => :edit)
    @list_row.up!

    respond_to do |format|
      format.js  { render(:update) {|page| page.replace_html 'listContainer', :partial => 'lists/list' } }
      format.xml { head :ok }
    end
  end
  
  def down
    @list_row = ListRow.find(params[:id])
    @selected_list_row = @list_row
    @list = List.find(@list_row.list_id, :include => [:list_columns, {:list_rows => [:list_cells]}], :scope => :edit)
    @list_row.down!

    respond_to do |format|
      format.js  { render(:update) {|page| page.replace_html 'listContainer', :partial => 'lists/list' } }
      format.xml { head :ok }
    end
  end
  
  def outdent
    @list_row = ListRow.find(params[:id])
    @selected_list_row = @list_row
    @list = List.find(@list_row.list_id, :include => [:list_columns, {:list_rows => [:list_cells]}], :scope => :edit)
    @list_row.outdent!

    respond_to do |format|
      format.js  { render(:update) {|page| page.replace_html 'listContainer', :partial => 'lists/list' } }
      format.xml { head :ok }
    end
  end

  def reorder
    @list = List.find(params[:id], :include => [:list_columns, {:list_rows => [:list_cells]}], :scope => :read)
    
    list_children = params.keys.find_all{|x| x =~ /item_\d+_children/}
    list_children.each do |child|
      params[child].each_with_index do |id, position|
         @list.list_rows.update(id, :position => position + 1)
       end
    end unless list_children.empty?

    params[:list].each_with_index do |id, position|
      next if id.blank?
      @list.list_rows.update(id, :position => position + 1)
    end if params[:list]
    
    render :nothing => true
  end

  private
  
    def load_application
      @application_name = 'lists'
    end

end