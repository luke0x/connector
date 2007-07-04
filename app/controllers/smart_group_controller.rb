=begin #(fold)
Copyright 2004-2007 Joyent Inc.

Redistribution and/or modification of this code is governed
by either the GPLv2 or Joyent Commercial Software licenses.

Report issues and contribute at http://dev.joyent.com/

$Id$
=end #(end)

class SmartGroupController < AuthenticatedController
  layout nil
#  after_filter :expire_sidebar

  def create
    return unless request.post?

    @smart_group = SmartGroup.create_from_params(params)
  ensure
    redirect_back_or_home
  end

  def rename
    return unless params[:name]
    return if params[:name].blank?
    return unless request.post?

    @smart_group = SmartGroup.find(params[:id], :scope => :edit)
    @smart_group.update_attribute(:name, params[:name])
  rescue ActiveRecord::RecordNotFound
  ensure
    redirect_back_or_home
  end

  def delete
    return unless request.post?

    @smart_group = SmartGroup.find(params[:id], :scope => :delete)
#    @smart_group_application_name = @smart_group.application_name # for sidebar caching
    @smart_group.destroy
  rescue ActiveRecord::RecordNotFound
  ensure
    redirect_back_or_home
  end

  def update
    return unless request.post?

    @smart_group = SmartGroup.find(params[:id], :scope => :edit)
    @smart_group.update_from_params(params)
  rescue ActiveRecord::RecordNotFound
  ensure
    redirect_back_or_home
  end

  private

    # def expire_sidebar
    #   if @smart_group_application_name
    #     expire_fragment %r{#{@smart_group_application_name}/sidebar}
    #   elsif @smart_group
    #     expire_fragment %r{#{@smart_group.application_name}/sidebar}
    #   end
    # end
end