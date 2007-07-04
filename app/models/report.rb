=begin #(fold)
Copyright 2004-2007 Joyent Inc.

Redistribution and/or modification of this code is governed
by either the GPLv2 or Joyent Commercial Software licenses.

Report issues and contribute at http://dev.joyent.com/

$Id$
=end #(end)

class Report < ActiveRecord::Base  
  acts_as_list :scope => :user_id
  
  belongs_to :report_description
  belongs_to :organization
  belongs_to :owner,      :class_name => 'User', :foreign_key => 'user_id'       
  belongs_to :reportable, :polymorphic => true 
  
  validates_presence_of :report_description_id
  validates_presence_of :organization_id
  validates_presence_of :user_id       
  validates_presence_of :reportable_id
  validates_presence_of :reportable_type
  validates_associated  :report_description
  
  before_save :valid_reportable_type
  
  def title
    report_description.title(self)  
  end 
  
  def summary
    report_description.summary(self)
  end       
  
  def html_url
    report_description.html_url(self)  
  end
  
  def js_url
    report_description.js_url(self)  
  end
                                      
  def group_type
    report_description.group_type(self)
  end
  
  private

    def valid_reportable_type
      report_description.reportable_type == reportable.class
    end
end