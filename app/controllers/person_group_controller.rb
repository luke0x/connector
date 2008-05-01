=begin #(fold)
++
Copyright 2004-2007 Joyent Inc.

Redistribution and/or modification of this code is 
governed by the GPLv2.

Report issues and contribute at http://dev.joyent.com/

$Id$
--
=end #(end)

class PersonGroupsController < ApplicationController
  # GET /person_groups
  # GET /person_groups.xml
  def index
    @person_groups = PersonGroup.find(:all)

    respond_to do |format|
      format.html # index.rhtml
      format.xml  { render :xml => @person_groups.to_xml }
    end
  end

  # GET /person_groups/1
  # GET /person_groups/1.xml
  def show
    @person_group = PersonGroup.find(params[:id])

    respond_to do |format|
      format.html # show.rhtml
      format.xml  { render :xml => @person_group.to_xml }
    end
  end

  # GET /person_groups/new
  def new
    @person_group = PersonGroup.new
  end

  # GET /person_groups/1;edit
  def edit
    @person_group = PersonGroup.find(params[:id])
  end

  # POST /person_groups
  # POST /person_groups.xml
  def create
    @person_group = PersonGroup.new(params[:person_group])

    respond_to do |format|
      if @person_group.save
        flash[:notice] = 'Person Group was successfully created.'
        format.html { redirect_to person_group_url(@person_group) }
        format.xml  { head :created, :location => person_group_url(@person_group) }
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => @person_group.errors.to_xml }
      end
    end
  end

  # PUT /person_groups/1
  # PUT /person_groups/1.xml
  def update
    @person_group = PersonGroup.find(params[:id])

    respond_to do |format|
      if @person_group.update_attributes(params[:person_group])
        flash[:notice] = 'Person Group was successfully updated.'
        format.html { redirect_to person_group_url(@person_group) }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @person_group.errors.to_xml }
      end
    end
  end

  # DELETE /person_groups/1
  # DELETE /person_groups/1.xml
  def destroy
    @person_group = PersonGroup.find(params[:id])
    @person_group.destroy

    respond_to do |format|
      format.html { redirect_to person_groups_url }
      format.xml  { head :ok }
    end
  end
end