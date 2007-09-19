=begin #(fold)
Copyright 2004-2007 Joyent Inc.

Redistribution and/or modification of this code is governed
by either the GPLv2 or Joyent Commercial Software licenses.

Report issues and contribute at http://dev.joyent.com/

$Id$
=end #(end)

class Comment < ActiveRecord::Base
  validates_presence_of :user_id
  validates_presence_of :body

  belongs_to :user
  belongs_to :commentable, :polymorphic => true

  def self.find_for_deletion(id, by_user)
    comment = Comment.find(id)                
    
    unless comment.user == by_user || comment.commentable.owner == by_user || by_user.admin?
      raise ActiveRecord::RecordNotFound
    end
    
    comment
  end
      
  def self.find_for_update(id)
    c = Comment.find(id)
    if c.user == User.current || c.commentable.owner == User.current
      c
    else
      raise ActiveRecord::RecordNotFound
    end
  end
end
