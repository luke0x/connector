=begin #(fold)
Copyright 2004-2007 Joyent Inc.

Redistribution and/or modification of this code is governed
by either the GPLv2 or Joyent Commercial Software licenses.

Report issues and contribute at http://dev.joyent.com/

$Id$
=end #(end)

class CommentsController < AuthenticatedController
  helper :people

  def add
    item = item_type(params[:item_type]).find(params[:id], :scope => :read)
    User.current.comment_on_item(item, params[:body])

    render :update do |page|
      page['comment-listing'].replace_html :partial => 'comments/comment', :collection => item.comments(true)
      page['comment-body'].value = ''
      page['comment-submit'].disabled = false
      page['comment-count'].replace_html item.comments(true).count
    end
  rescue ActiveRecord::RecordNotFound
    render :nothing => true
  rescue RuntimeError => e
    logger.error e
    render :nothing => true
  end

  def remove
    comment = Comment.find(params[:id], :scope => :read) # don't have polymorphic delete scope yet
    item = comment.commentable
    comment.destroy

    render :update do |page|
      page.visual_effect :fade, "comment-#{comment.id}"
      page['comment-count'].replace_html item.comments(true).count
    end
  rescue ActiveRecord::RecordNotFound
    render :nothing => true
  rescue RuntimeError => e
    logger.error e
    render :nothing => true
  end

  def edit
    comment = Comment.find(params[:id], :scope => :edit)
    comment.update_attribute(:body, params[:body])

    render :update do |page|
      page["comment-#{comment.id}"].replace :partial => 'comments/comment', :locals => {:comment => comment}
      page["editComment#{comment.id}"].hide
      page["viewComment#{comment.id}"].show
    end
  rescue ActiveRecord::RecordNotFound
    render :nothing => true
  end
end