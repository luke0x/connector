=begin #(fold)
Copyright 2004-2007 Joyent Inc.

Redistribution and/or modification of this code is governed
by either the GPLv2 or Joyent Commercial Software licenses.

Report issues and contribute at http://dev.joyent.com/

$Id$
=end #(end)

CREATE_VIEW=<<END
CREATE VIEW user_emails AS SELECT u.id,  
                                  u.username || '@' ||  d.email_domain AS email_address 
                           FROM   users u, 
                                  organizations o, 
                                  domains d 
                           WHERE  u.organization_id = o.id 
                             AND  d.organization_id = o.id
END

class CreateUserEmailsView < ActiveRecord::Migration
  def self.up
    execute CREATE_VIEW
  end

  def self.down        
    execute "DROP VIEW user_emails"
  end
end
