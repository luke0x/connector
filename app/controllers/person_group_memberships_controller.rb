=begin #(fold)
++
Copyright 2004-2007 Joyent Inc.

Redistribution and/or modification of this code is 
governed by the GPLv2.

Report issues and contribute at http://dev.joyent.com/

$Id$
--
=end #(end)

class PersonGroupMembershipsController < AuthenticatedController

  before_filter :get_person_group
  before_filter :get_person, :only => [:delete]
  before_filter :load_sort_order, :only => [:index, :create]
  
  def create
    people_to_add = Person.find(params[:person_ids], :scope => :read)
    
    respond_to do |format|
      format.html do
        if current_user.can_create_on?(@person_group) and @person_group.people << people_to_add
          setup_objects_for_view
          render(:action => 'index')
        else
          # TODO: define where to go (?)
          redirect_to(people_list_url(@person_group)) and return
        end
      end
    end
    
  end
  
  # removes memberships from contextualized person group
  def destroy

    if params[:ids].blank?
      redirect_back_or_home and return
    end
    
    ids = params[:ids].split(',')
    deleted_items = []

    ids.each do |id|
      begin
        membership = PersonGroupMembership.find(id)
        if current_user.can_delete_from?(@person_group)
          membership.destroy
          deleted_items << membership
        end
      rescue ActiveRecord::RecordNotFound
      end
    end

    respond_to do |format|
      format.html { redirect_back_or_home }
      format.js   {
        render :update do |page|
          deleted_items.each do |item|
            page << "Item.removeFromList('#{item.dom_id}');"
          end
          page << 'JoyentPage.refresh()';
          page.replace_html("drawerAddPeople", :partial => 'person_group_memberships/add_people')
        end
      }
    end      
    
  end
  
  protected

    def get_person_group
      @person_group = PersonGroup.find(params[:person_group_id], :scope => :read)
    end

end
