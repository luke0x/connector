=begin #(fold)
Copyright 2004-2007 Joyent Inc.

Redistribution and/or modification of this code is governed
by either the GPLv2 or Joyent Commercial Software licenses.

Report issues and contribute at http://dev.joyent.com/

$Id$
=end #(end)

require File.dirname(__FILE__) + '/../test_helper'
require 'files_controller'
require 'flexmock'

# Re-raise errors caught by the controller.
class FilesController
  def rescue_action(e) raise e end;
  def send_joyent_file(file, attachment)
    @sent_file = file
  end
end

class FilesControllerTest < Test::Unit::TestCase
  include FlexMock::TestCase
  fixtures all_fixtures
  
  def setup
    @controller = FilesController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
  end

  def test_index_redirects
    login_person(:ian)
    get :index

    assert_response :redirect
    assert_redirected_to files_list_route_url(:folder_id => folders(:ian_documents).id)
  end

  def test_all_notifications
    login_person(:ian)
    get :notifications, {:all => ''}

    assert_response :success
    assert assigns(:notifications)
    assert_toolbar([:new_notifications])
  end

  def test_notifications
    login_person(:ian)
    get :notifications

    assert assigns(:paginator)
    assert assigns(:notifications)
    assert_toolbar([:all_notifications])
  end
  
  def test_notifications_ajax  
    login_person(:ian)
    xhr :get, :notifications

    assert assigns(:paginator)
    assert assigns(:notifications)
  end

  def test_list
    login_person(:ian)
    get :list, :folder_id => folders(:ian_documents).id

    assert_response :success
    assert assigns(:files)
    assert_toolbar([:quota, :new, :copy, :move, :delete])
  end   
  
  def test_list_ajax
    login_person(:ian)
    xhr :get, :list, :folder_id => folders(:ian_documents).id

    assert_response :success
    assert assigns(:files)
    assert_template('_files')
  end

  def test_list_others_folder
    login_person(:peter)
    get :list, :folder_id => folders(:ian_documents).id

    assert_response :success
    assert assigns(:files)
    assert_toolbar([:quota, :new, :copy])
  end
  
  def test_create_form_is_on_page
    login_person(:ian)
    get :list, :folder_id => folders(:ian_documents).id

    assert_response :success
    assert @response.body =~ /#{file_create_url}/
  end
  
  def test_show
    login_person(:ian)
    get :show, :folder_id => folders(:ian_documents).id, :id => joyent_files(:ian_jpg).id
    
    assert_equal joyent_files(:ian_jpg).id, assigns(:file).id
    assert assigns(:file)
    assert assigns(:folder)
    assert assigns(:group_name)
    assert @response.body =~ /<div id="preview_/
    assert_toolbar([:quota, :new, :edit, :move, :copy, :delete])
  end
  
  def test_show_not_owner_not_restricted
    login_person(:peter)
    get :show, :folder_id => folders(:ian_documents).id, :id => joyent_files(:ian_jpg).id
    
    assert_equal joyent_files(:ian_jpg).id, assigns(:file).id
    assert_toolbar([:quota, :new, :copy])
  end
  
  def test_show_restricted_item
    # What should happen when we try to view a restricted item?
    login_person(:peter)
    get :show, :id => joyent_files(:bernards_secret_file).id
    
    assert_redirected_to files_home_url
  end
  
  # We are going to test that the file is deleted too
  def test_delete
    login_person(:ian)
    file = joyent_files(:ians_dog_jpg)
    file_path = file.path_on_disk
    @request.env["HTTP_REFERER"] = '/files/1'

    assert MockFS.file.exists?(file_path)
    post :delete, :ids => joyent_files(:ians_dog_jpg).id
    
    assert_redirected_to '/files/1'
    assert !MockFS.file.exists?(file_path)
  end

  def test_strongspace_delete
    login_person(:ian)
    @request.env["HTTP_REFERER"] = '/files/strongspace/1'
    
    flexstub(StrongspaceFile).should_receive(:find).with(users(:ian), 'foo/bar/baz.txt', users(:ian)).once.returns {
      flexmock('ssfile') {|m| m.should_receive(:remove!).once}
    }
    get :strongspace_delete, :owner_id => users(:ian).id, :ids => 'foo/bar/baz.txt'
    
    assert_redirected_to '/files/strongspace/1'
  end
  
  def test_delete_not_owner
    # XXX what should happen here?
  end
  
  def test_delete_restricted
    login_person(:peter)
    @request.env["HTTP_REFERER"] = '/files/4'
    get :delete, :ids => joyent_files(:ians_dog_jpg).id
    
    assert_redirected_to files_list_route_url(:folder_id => joyent_files(:ians_dog_jpg).folder.id)
    assert JoyentFile.find(joyent_files(:ians_dog_jpg).id)
  end

  def test_delete_multiple
    login_person(:ian)
    fp1 = joyent_files(:ian_jpg).path_on_disk
    fp2 = joyent_files(:ian_html).path_on_disk
    @request.env["HTTP_REFERER"] = '/files/1'
    post :delete, :ids => "#{joyent_files(:ian_jpg).id},#{joyent_files(:ian_html).id}"
    
    assert_redirected_to files_list_route_url(:folder_id => joyent_files(:ian_jpg).folder.id)
    assert_nil JoyentFile.find_by_id(joyent_files(:ian_jpg).id)
    assert_nil JoyentFile.find_by_id(joyent_files(:ian_html).id)
    assert !MockFS.file.exist?(fp1)
    assert !MockFS.file.exist?(fp2)
  end

  def test_strongspace_delete_multiple
    login_person(:ian)
    @request.env["HTTP_REFERER"] = '/files/strongspace/1'

    flexstub(StrongspaceFile).should_receive(:find).with(users(:ian), 'foo/bar/baz.txt', users(:ian)).once.returns {
      flexmock('ssfile') {|m| m.should_receive(:remove!).once}
    }
    flexstub(StrongspaceFile).should_receive(:find).with(users(:ian), 'foo/bar/quux.txt', users(:ian)).once.returns {
      flexmock('ssfile') {|m| m.should_receive(:remove!).once}
    }

    get :strongspace_delete, :owner_id => users(:ian).id, :ids => "foo/bar/baz.txt,foo/bar/quux.txt"
    
    assert_redirected_to '/files/strongspace/1'
  end
  
  def test_delete_multiple_not_owner
    # XXX what should happen here?
  end
  
  def test_delete_multiple_restricted_if_not_owner_of_all
    login_person(:peter)
    @request.env["HTTP_REFERER"] = '/files/4'
    get :delete, :ids => joyent_files(:ians_dog_jpg).id
    
    assert_redirected_to files_list_route_url(:folder_id => joyent_files(:ians_dog_jpg).folder.id)
    assert JoyentFile.find(joyent_files(:ians_dog_jpg).id)
  end
  
  def test_edit_form
    login_person(:ian)
    get :edit, :folder_id => folders(:ian_documents).id, :id => joyent_files(:ian_jpg).id
    
    assert_response :success
    assert_template 'edit'

    assert assigns(:folder)
    assert assigns(:group_name)
    assert assigns(:file)
    assert_equal joyent_files(:ian_jpg).id, assigns(:file).id
  end
  
  def test_edit_form_restricted
    login_person(:peter)
    get :edit, :id => joyent_files(:ians_dog_jpg).id
    
    assert_redirected_to files_home_url
  end

  # also regression for 2788
  def test_edit
    login_person(:ian)
    new_name = 'radical'
    new_notes = 'ok cool right'
    assert_not_equal new_name, joyent_files(:ian_jpg).filename_without_extension
    assert_not_equal new_notes, joyent_files(:ian_jpg).notes
    post :edit, :folder_id => folders(:ian_documents).id, :id => joyent_files(:ian_jpg).id, :file => {:name => new_name, :notes => new_notes}

    assert_response :redirect
    assert_redirected_to files_show_route_url(:id => joyent_files(:ian_jpg).id)
    joyent_files(:ian_jpg).reload
    assert_equal new_name, joyent_files(:ian_jpg).filename_without_extension
    assert_equal new_notes, joyent_files(:ian_jpg).notes
    
  end
  
  def test_peek
    login_person(:ian)
    xhr :get, :show, {:id => joyent_files(:ian_jpg).id}
    assert_response :success
    assert_template '_peek'
  end
  
  def test_preview
    login_person(:ian)
    xhr :post, :show, :id => joyent_files(:ian_jpg).id

    assert_response :success
    assert_template '_peek'

    assert assigns(:file)
    assert_equal joyent_files(:ian_jpg).id, assigns(:file).id
  end
  
  def test_preview_not_owner_not_restricted
    login_person(:peter)
    xhr :post, :show, :id => joyent_files(:ian_jpg).id
    
    assert_equal joyent_files(:ian_jpg).id, assigns(:file).id
  end
  
  def test_preview_restricted_item
    login_person(:peter)
    xhr :post, :show, :id => joyent_files(:bernards_secret_file).id
    
    assert_redirected_to files_home_url
  end
  
  def test_upload_a_file
    login_person(:ian)
    post :create, :upload_0=>fixture_file_upload('/files/rails-xtra-large-blue.jpg', 'image/jpg'),
                  :folder_id=>folders(:ian_pictures).id
    f = assigns(:file)
        
    assert f
#    assert f.valid?
    assert_redirected_to files_list_route_url(:folder_id => folders(:ian_pictures).id) 
  end

  def test_browser
    login_person(:ian)
    get :browser
    assert_response :success
  end
  
  # def test_download
  #   login_person(:ian)
  #   get :download, {:id=>2}
  #   assert_response :success
  # end
  
  def test_download_of_a_bad_id
    login_person(:ian)
    get :download, {:id=>999}
    assert_redirected_to files_home_url
  end
  
  # def test_download_inline
  #   login_person(:ian)
  #   get :download_inline, {:id=>2}
  #   assert_response :success
  # end
  
  def test_download_inline_of_a_bad_id
    login_person(:ian)
    get :download_inline, {:id=>999}
    assert_redirected_to files_home_url
  end
  
  def test_that_widget_thing_works
    login_person(:ian)
    get :list, :folder_id => folders(:ian_documents).id

    assert_response :success
    assert @response.body =~ /0\/10 GB Used/
    assert @response.body =~ /<strong class="bar" style="width: 0%;"><\/strong>/
  end
  
  def test_smart_group_attributes_are_right
    login_person(:ian)
    get :list, :folder_id => folders(:ian_documents).id
    assert_response :success
    assert_smart_group_attributes_assigned smart_group_descriptions(:files)
  end
  
  def test_create_folder
    login_person(:ian)
    assert ! users(:ian).folders.find_by_name("omgomgomgomgomg")
    post :create_folder, {:group_name=>"omgomgomgomgomg", :parent_id => users(:ian).files_documents_folder.id}
    assert_response :redirect
    
    f = users(:ian).folders.find_by_name("omgomgomgomgomg")
    assert f
  end

  def test_strongspace_create_folder
    login_person(:ian)
    
    flexstub(StrongspaceFolder).should_receive(:create).with(users(:ian), 'foo/zomg').once.returns {
      flexmock('ssfolder')
    }
    
    # Here we pass parent_path instead of parent_id, and that's how create_folder
    # knows the difference between Folder and StrongspaceFolder
    post :create_folder, {:group_name=>"zomg", :parent_path => 'foo'}
    assert_response :redirect
  end
  
  # added preview functionality
  def test_regression_for_2640
    login_person(:ian)
    get :show, :id => joyent_files(:ian_jpg).id

    assert @response.body =~ /<div id="preview_/
  end

  def test_regression_for_2678
    login_person(:ian)
    post :create, :upload_0=>fixture_file_upload('/files/t.txt', 'text/plain'),
                  :folder_id=>folders(:ian_pictures).id
    f = assigns(:file)
        
    assert f
#    assert f.valid?
    assert_redirected_to files_list_route_url(:folder_id => folders(:ian_pictures).id) 
  end
  
  def test_regression_for_2770
    login_person(:ian)
    post :create, :upload_0=>fixture_file_upload('/files/dog.jpg', 'image/jpg'),
                  :folder_id=>folders(:ian_pictures_vacation).id
    f = assigns(:file)
        
    assert f
#    assert f.valid?
    assert_redirected_to files_list_route_url(:folder_id => folders(:ian_pictures_vacation).id) 
#    assert_equal "dog-1.jpg", f.filename
  end
  
  # also regression for 2688
  def test_delete_group
    login_person(:ian)
    i = folders(:ian_pictures).id
    post :delete_group, :id => i
    assert_redirected_to files_home_url
    assert_raises(ActiveRecord::RecordNotFound) {Folder.find(i)}
  end
  
  def test_smart_list
    login_person(:ian)
    get :smart_list, {:smart_group_id => smart_groups(:ian_files).url_id}
    assert_response :success
    assert assigns(:files)
    assert assigns(:group_name)
    assert assigns(:smart_group)
    assert_toolbar([:quota, :new, :move, :copy, :delete])
  end 
  
  def test_smart_list_ajax                                               
    login_person(:ian)
    xhr :get, :smart_list, {:smart_group_id => smart_groups(:ian_files).url_id}
    assert_response :success    
    assert assigns(:group_name)
    assert assigns(:smart_group)
    assert assigns(:files)
    assert_template('_files')  
  end    

  def test_smart_show
    login_person(:ian)
    get :smart_show, {:id => joyent_files(:ian_jpg).id, :smart_group_id => smart_groups(:ian_files).url_id}
                                                             
    assert assigns(:file)      
    assert_equal joyent_files(:ian_jpg).id, assigns(:file).id
    assert assigns(:smart_group)
    assert assigns(:group_name)
    assert_toolbar([:quota, :new, :edit, :move, :copy, :delete])
  end                
  
  def test_smart_preview
    login_person(:ian)
    xhr :post, :smart_show, {:id => joyent_files(:ian_jpg).id, :smart_group_id => smart_groups(:ian_files).url_id}

    assert_response :success
    assert_template '_peek'

    assert assigns(:file)
    assert_equal joyent_files(:ian_jpg).id, assigns(:file).id
  end                
  
  def test_smart_edit
    login_person(:ian)
    get :smart_edit, {:id => joyent_files(:ian_jpg).id, :smart_group_id => smart_groups(:ian_files).url_id}
    
    assert_response :success
    assert_template 'edit'

    assert assigns(:smart_group)
    assert assigns(:group_name)
    assert assigns(:file)
    assert_equal joyent_files(:ian_jpg).id, assigns(:file).id
  end                
  
  # Test regression for #2887
  def test_non_owner_delete
    login_person(:peter)   
    @request.env["HTTP_REFERER"] = '/files/1'
    
    assert JoyentFile.find_by_id(joyent_files(:ians_dog_jpg).id)
    get :delete, {:ids => joyent_files(:ians_dog_jpg).id}
    assert JoyentFile.find_by_id(joyent_files(:ians_dog_jpg).id)  
  end                      

  # Test regression for #2887  
  def test_non_owner_delete_smart
    login_person(:peter)   
    @request.env["HTTP_REFERER"] = '/files/1'
    
    assert JoyentFile.find_by_id(joyent_files(:ians_dog_jpg).id)
    get :delete, {:ids => joyent_files(:ians_dog_jpg).id}
    assert JoyentFile.find_by_id(joyent_files(:ians_dog_jpg).id)
  end
  
  def test_move  
    login_person(:ian)   
    post :move, {:ids => joyent_files(:ian_jpg).id, :new_group_id => folders(:ian_pictures).id} 
    assert_response :redirect              
  end          

  def test_strongspace_move
    login_person(:ian)

    flexstub(StrongspaceFolder).should_receive(:find).with(users(:ian), 'quux', users(:ian)).once.returns {
      flexstub('ssfolder') { |m| m.should_receive(:full_path).returns('/home/data/quux') }
    }
    
    flexstub(StrongspaceFile).should_receive(:find).with(users(:ian), 'foo/bar.txt', users(:ian)).once.returns {
      flexmock('ssfile') { |m| m.should_receive(:move_to).with_any_args.once}
    }
    
    
    post :strongspace_move, :owner_id => users(:ian).id, :ids => 'foo/bar.txt', :new_group_id => 'quux'
    
    assert_response :redirect
  end    

  def test_strongspace_move_multiple
    login_person(:ian)

    flexstub(StrongspaceFolder).should_receive(:find).with(users(:ian), 'quux', users(:ian)).once.returns {
      flexstub('ssfolder') { |m| m.should_receive(:full_path).returns('/home/data/quux') }
    }
    
    flexstub(StrongspaceFile).should_receive(:find).with(users(:ian), 'foo/bar.txt', users(:ian)).once.returns {
      flexmock('ssfile') { |m| m.should_receive(:move_to).with_any_args.once}
    }

    flexstub(StrongspaceFile).should_receive(:find).with(users(:ian), 'foo/baz.txt', users(:ian)).once.returns {
      flexmock('ssfile') { |m| m.should_receive(:move_to).with_any_args.once}
    }
    
    
    post :strongspace_move, :owner_id => users(:ian).id, :ids => 'foo/bar.txt,foo/baz.txt', :new_group_id => 'quux'
    
    assert_response :redirect
  end    
  
  def test_copy       
    login_person(:ian)
    post :copy, {:ids => joyent_files(:ian_jpg).id, :new_group_id => folders(:ian_pictures).id} 
    assert_response :redirect
  end    

  def test_strongspace_copy
    login_person(:ian)

    flexstub(StrongspaceFolder).should_receive(:find).with(users(:ian), 'quux', users(:ian)).once.returns {
      flexstub('ssfolder') { |m| m.should_receive(:full_path).returns('/home/data/quux') }
    }
    
    flexstub(StrongspaceFile).should_receive(:find).with(users(:ian), 'foo/bar.txt', users(:ian)).once.returns {
      flexmock('ssfile') { |m| m.should_receive(:copy_to).with_any_args.once}
    }
    
    
    post :strongspace_copy, :owner_id => users(:ian).id, :ids => 'foo/bar.txt', :new_group_id => 'quux'
    
    assert_response :redirect
  end    

  def test_strongspace_copy_multiple
    login_person(:ian)

    flexstub(StrongspaceFolder).should_receive(:find).with(users(:ian), 'quux', users(:ian)).once.returns {
      flexstub('ssfolder') { |m| m.should_receive(:full_path).returns('/home/data/quux') }
    }
    
    flexstub(StrongspaceFile).should_receive(:find).with(users(:ian), 'foo/bar.txt', users(:ian)).once.returns {
      flexmock('ssfile') { |m| m.should_receive(:copy_to).with_any_args.once}
    }

    flexstub(StrongspaceFile).should_receive(:find).with(users(:ian), 'foo/baz.txt', users(:ian)).once.returns {
      flexmock('ssfile') { |m| m.should_receive(:copy_to).with_any_args.once}
    }
    
    
    post :strongspace_copy, :owner_id => users(:ian).id, :ids => 'foo/bar.txt,foo/baz.txt', :new_group_id => 'quux'
    
    assert_response :redirect
  end    
                              
  # There was a problem with copying a file to the same location it already is
  def test_regression_for_2915
    login_person(:ian)
    file = JoyentFile.find_by_filename('foo.jpg')       
    
    assert_equal file.id, joyent_files(:ian_jpg).id
    assert_equal file.folder.id, folders(:ian_documents).id   
    
    file = JoyentFile.find_by_filename('foo-1.jpg')       
    
    assert_nil file
    
    post :copy, {:ids => joyent_files(:ian_jpg).id, :new_group_id => folders(:ian_documents).id} 
    assert_response :redirect  
    
    file = JoyentFile.find_by_filename('foo-1.jpg')       

    assert       file
    assert_equal file.folder.id, folders(:ian_documents).id   
    
    post :copy, {:ids => joyent_files(:ian_jpg).id, :new_group_id => folders(:ian_documents).id} 
    assert_response :redirect  
    
    file = JoyentFile.find_by_filename('foo-2.jpg')       

    assert       file
    assert_equal file.folder.id, folders(:ian_documents).id
  end 

  # ajax show was sometimes using layout
  def test_regression_for_3028
    login_person(:ian)
    xhr :post, :show, :id => joyent_files(:ian_jpg).id

    assert_response :success
    assert_template '_peek'
    assert_no_layout
  end

  # make sure the form url is correct
  def test_regression_for_3229
    login_person(:ian)
    get :list, :folder_id => folders(:ian_documents).id

    assert @response.body =~ /#{file_create_url}/
  end
  
  def test_user_request_is_created
    login_person(:ian)
    get :list, :folder_id=>folders(:ian_documents).id
    
    assert @user_request = UserRequest.find(:first)
    assert_equal users(:ian),                      @user_request.user
    assert_equal organizations(:joyent).name,      @user_request.organization
    assert_equal users(:ian).username,             @user_request.username
    assert_equal "FilesController#list",           @user_request.action
    assert_equal @request.session.session_id,      @user_request.session_id
  end

  def test_valid_sort_fields
    assert @controller.send(:valid_sort_fields).is_a?(Array)
    assert @controller.send(:valid_sort_fields).length > 0
  end

end