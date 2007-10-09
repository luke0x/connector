=begin #(fold)
++
Copyright 2004-2007 Joyent Inc.

Redistribution and/or modification of this code is 
governed by the GPLv2.

Report issues and contribute at http://dev.joyent.com/

$Id$
--
=end #(end)

class ReportDescription < ActiveRecord::Base
  validates_presence_of   :name               
  validates_uniqueness_of :name   

  has_many :reports, :dependent => :destroy

  before_save { |rd| rd.fetcher rescue false }
  
  delegate :title,           :to => :fetcher
  delegate :summary,         :to => :fetcher
  delegate :html_url,        :to => :fetcher
  delegate :js_url,          :to => :fetcher
  delegate :group_type,      :to => :fetcher
  delegate :reportable_type, :to => :fetcher
                                       
  def fetcher
    Object.const_get("#{name.camelize}Fetcher")
  end                              
end