=begin #(fold)
Copyright 2004-2007 Joyent Inc.

Redistribution and/or modification of this code is governed
by either the GPLv2 or Joyent Commercial Software licenses.

Report issues and contribute at http://dev.joyent.com/

$Id$
=end #(end)

class ReportsController < AuthenticatedController

  def index
    @view_kind  = 'report'
    @group_name = 'Workspace'
  end

  # NOTE: A report_description_id, reportable_id and user_id is a unique combination
  # don't need to worry about reportable_type_id since each report_description only deals with one type
  def create
    current_user.create_report(params[:report_description_id], params[:reportable_id])

    render :nothing => true
  rescue
    render :nothing => true, :status => 401  
  end
  
  def destroy
    report = if params[:id]
      Report.find(params[:id], :scope => :delete)
    elsif params[:report_description_id] && params[:reportable_id]
      Report.find(:first,
        :conditions => ["report_description_id = ? AND reportable_id = ?", params[:report_description_id], params[:reportable_id]],
        :scope => :delete)
    end
    report.destroy if report
    
    render :nothing => true  
  rescue
    render :nothing => true, :status => 401  
  end  
  
  def reorder
    if params[:report_list] && params[:report_list].kind_of?(Array)
      params[:report_list].each_with_index do |report_id, position|
        report = Report.find(report_id, :scope => :edit)
        report.update_attribute(:position, position + 1) if report
      end
    end

    render :nothing => true
  rescue
    render :nothing => true, :status => 401  
  end    

  private
  
    def load_application
      @application_name = 'connect'
    end
end