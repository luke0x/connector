=begin #(fold)
Copyright 2004-2007 Joyent Inc.

Redistribution and/or modification of this code is governed
by either the GPLv2 or Joyent Commercial Software licenses.

Report issues and contribute at http://dev.joyent.com/

$Id$
=end #(end)

class OrganizationObserver < ActiveRecord::Observer
  observe Organization
  
  def after_create(organization)
    MockFS.file_utils.mkdir_p organization.icons_path
    MockFS.file_utils.mkdir_p organization.users_path
  end
                                                                     
  def before_destroy(organization)
    # Cache the system_domain so we can use it later
    organization.system_domain  
  end
  
  def after_destroy(organization)
    MockFS.file_utils.rm_rf organization.root_path
    JoyentMaildir::Base.remove_organization(organization)
  end
end
