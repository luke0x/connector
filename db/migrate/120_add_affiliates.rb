=begin #(fold)
Copyright 2004-2007 Joyent Inc.

Redistribution and/or modification of this code is governed
by either the GPLv2 or Joyent Commercial Software licenses.

Report issues and contribute at http://dev.joyent.com/

$Id$
=end #(end)

class AddAffiliates < ActiveRecord::Migration
  def self.up
    Affiliate.create(:id => 1, :name => 'joyent')
    Affiliate.create(:id => 2, :name => 'corel')
  end

  def self.down
    Affiliate.destroy(1)
    Affiliate.destroy(2)
  end
end
