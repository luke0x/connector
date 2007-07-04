=begin #(fold)
Copyright 2004-2007 Joyent Inc.

Redistribution and/or modification of this code is governed
by either the GPLv2 or Joyent Commercial Software licenses.

Report issues and contribute at http://dev.joyent.com/

$Id$
=end #(end)

class TagController < AuthenticatedController
  layout nil
  
  ERROR_MSG = _("You no longer have access to this item.")

  def tag_item
    tag_name = params[:tag_name]
    return if tag_name.blank?
    page_js = []

    dom_ids = params[:dom_ids].split(',')
    dom_ids.each do |dom_id|
      next unless @item = find_by_dom_id(dom_id)
      tagging = User.current.tag_item(@item, tag_name)
      page_js << tagging_to_jsar(tagging)
    end

    respond_to do |wants|
      wants.html { redirect_back_or_home }
      wants.js   {
        render :update do |page|
          page << tag_to_jsar(Tag.find_by_name(tag_name))
          page << page_js.join("\n")
          page << "Sidebar.Tags.refresh();"
        end
      }
    end      
  rescue ActiveRecord::RecordNotFound
    render :text => ERROR_MSG
  end

  def untag_item
    tag_name = params[:tag_name]
    return if tag_name.blank?
    page_js = []

    dom_ids = params[:dom_ids].split(',')
    dom_ids.each do |dom_id|
      next unless @item = find_by_dom_id(dom_id)
      tagging = User.current.untag_item(@item, tag_name)
      if tagging
        page_js << "Tagging.destroy('#{tagging.dom_id}');"
      else
        page_js << "Tagging.destroyByTagNameAndItemDomIds('#{tag_name}', '#{dom_id}');"
      end
    end

    respond_to do |wants|
      wants.html { redirect_back_or_home }
      wants.js   {
        render :update do |page|
          page << page_js.join("\n")
          page << "Sidebar.Tags.refresh();"
        end
      }
    end      
  rescue ActiveRecord::RecordNotFound
    render :text => ERROR_MSG
  end

  # the tag definition name will come through as either
  # :tag_definition_name (for the tag palette) or :tag (which is a nested array) for the smart group builder
  # TODO: have the smart group builder use 'tag_name' instead?
  def auto_complete
    if params.has_key?(:tag_name)
      @needle = params[:tag_name].downcase
    elsif params.has_key?(:tag)
      @needle = params[:tag].to_a[0][1]
    end

    # empty searches return nothing, instead of everything
    unless @needle
      render :text => '<ul><li></li></ul>'
      return true
    end

    # get the matched tag definitions
    @tags = Organization.current.tags.find(:all, :conditions => ['LOWER(name) LIKE ?', "%#{@needle.downcase}%"],
                                           :order => 'LOWER(name)', :limit => 20)
  end
end