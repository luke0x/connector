=begin #(fold)
++
Copyright 2004-2007 Joyent Inc.

Redistribution and/or modification of this code is 
governed by the GPLv2.

Report issues and contribute at http://dev.joyent.com/

$Id$
--
=end #(end)

class Comment < ActiveRecord::Base
  validates_presence_of :user_id
  validates_presence_of :body

  belongs_to :user
  belongs_to :commentable, :polymorphic => true

  def self.find_for_deletion(id, by_user)
    comment = Comment.find(id)                
    
    unless comment.user == by_user || comment.commentable.owner == by_user || (by_user.admin? && by_user.organization == comment.commentable.organization)
      raise ActiveRecord::RecordNotFound
    end
    
    comment
  end
end
