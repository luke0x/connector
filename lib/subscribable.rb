=begin #(fold)
Copyright 2004-2007 Joyent Inc.

Redistribution and/or modification of this code is governed
by either the GPLv2 or Joyent Commercial Software licenses.

Report issues and contribute at http://dev.joyent.com/

$Id$
=end #(end)

module Subscribable
  def self.included(base)
    base.has_many :subscriptions, :dependent => :destroy,       :as => :subscribable
    base.has_many :subscribers,   :through =>   :subscriptions, :source => :owner
  end
end