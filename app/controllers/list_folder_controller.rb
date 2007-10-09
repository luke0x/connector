=begin #(fold)
++
Copyright 2004-2007 Joyent Inc.

Redistribution and/or modification of this code is 
governed by the GPLv2.

Report issues and contribute at http://dev.joyent.com/

$Id$
--
=end #(end)

class ListFoldersController < ApplicationController
  # GET /list_folders
  # GET /list_folders.xml
  def index
    @list_folders = ListFolder.find(:all)

    respond_to do |format|
      format.html # index.rhtml
      format.xml  { render :xml => @list_folders.to_xml }
    end
  end

  # GET /list_folders/1
  # GET /list_folders/1.xml
  def show
    @list_folder = ListFolder.find(params[:id])

    respond_to do |format|
      format.html # show.rhtml
      format.xml  { render :xml => @list_folder.to_xml }
    end
  end

  # GET /list_folders/new
  def new
    @list_folder = ListFolder.new
  end

  # GET /list_folders/1;edit
  def edit
    @list_folder = ListFolder.find(params[:id])
  end

  # POST /list_folders
  # POST /list_folders.xml
  def create
    @list_folder = ListFolder.new(params[:list_folder])

    respond_to do |format|
      if @list_folder.save
        flash[:message] = 'List Folder was successfully created.'
        format.html { redirect_to list_folder_url(@list_folder) }
        format.xml  { head :created, :location => list_folder_url(@list_folder) }
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => @list_folder.errors.to_xml }
      end
    end
  end

  # PUT /list_folders/1
  # PUT /list_folders/1.xml
  def update
    @list_folder = ListFolder.find(params[:id])

    respond_to do |format|
      if @list_folder.update_attributes(params[:list_folder])
        flash[:message] = 'List Folder was successfully updated.'
        format.html { redirect_to list_folder_url(@list_folder) }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @list_folder.errors.to_xml }
      end
    end
  end

  # DELETE /list_folders/1
  # DELETE /list_folders/1.xml
  def destroy
    @list_folder = ListFolder.find(params[:id], :scope => :delete)
    @list_folder.destroy

    respond_to do |format|
      format.html { redirect_to list_folders_url }
      format.xml  { head :ok }
    end
  end
  
end