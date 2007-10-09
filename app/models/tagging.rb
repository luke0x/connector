=begin #(fold)
++
Copyright 2004-2007 Joyent Inc.

Redistribution and/or modification of this code is 
governed by the GPLv2.

Report issues and contribute at http://dev.joyent.com/

$Id$
--
=end #(end)

class Tagging < ActiveRecord::Base
  validates_presence_of :tag_id
  validates_presence_of :tagger_id
  validates_presence_of :taggable_id
  validates_presence_of :taggable_type
  
  belongs_to :tag
  belongs_to :taggable, :polymorphic => true
  belongs_to :tagger, :class_name => 'User', :foreign_key => 'tagger_id'
end