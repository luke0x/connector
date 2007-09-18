=begin #(fold)
Copyright 2004-2007 Joyent Inc.

Redistribution and/or modification of this code is governed
by either the GPLv2 or Joyent Commercial Software licenses.

Report issues and contribute at http://dev.joyent.com/

$Id$
=end #(end)

require File.dirname(__FILE__) + '/../test_helper'

class UserTest < Test::Unit::TestCase
  fixtures all_fixtures

  include CRUDTest
  
  crud_data 'person_id'       => 10,
            'organization_id' => 1,
            'username'        => 'fred',
            'password'        => 'wilmabhawt',
            'password_sha1'   => '??',
            'admin'           => false,
            'identity_id'     => 1
            
  crud_required 'person_id', 'organization_id', 'username', 'password', 'identity_id'
  
  def test_person_link
    assert users(:ian).person.is_a?(Person)
  end

  def test_person_destroy_dependency
    pid = people(:user_with_restrictions).id
    users(:user_with_restrictions).destroy
    
    assert_nil Person.find_by_id(pid)
  end

  def test_folders_create_and_destroy
    user = assert_create
    
    user.reload # hax hax
    
    assert_not_nil user.documents_folder
    l = user.documents_folder.path_on_disk
    assert MockFS.file.exists?(l)
    user.destroy
    assert !MockFS.file.exists?(l)
  end
  
  def test_username_format
    @test_data['username'] = '##4sdf'
    assert !User.new(@test_data).valid?
    
    @test_data['username'] = 'a' * 51
    assert !User.new(@test_data).valid?
  end
  
  def test_password_format
    @test_data['password'] = 'aaa'
    
    assert !User.new(@test_data).valid?
  end
  
  def test_username_unique_per_organization
    # Cannot add another user 'ian' to 'joyent'
    assert User.find(:first, :conditions => ["id = 1 AND organization_id = 1"])
    assert !User.new(:person_id => 1, :organization_id => 1, :username => 'ian', :password => 'pass', :identity_id => 999).valid?
    
    # Can add user 'ian' to 'textdrive'
    assert User.new(:person_id => 99999, :organization_id => 2, :username => 'ian', :password => 'pass', :identity_id => 9999).valid?
  end
  
  def test_password_encrypted_on_create
    user = assert_create
    assert_not_equal @test_data['password'], user.password
  end
  
  def test_plaintext_password
    assert_equal 'testpass', users(:ian).plaintext_password
  end
  
  def test_update_password
    user = users(:ian)
    user.update_password('pass', 'pass')
    user.save
    assert_equal 'pass', user.plaintext_password
  end
  
  def test_authenticate
    assert users(:ian).authenticate('testpass')
    assert !users(:ian).authenticate('foo')
  end
  
  def test_ensure_organization_id_is_required
    @test_data.delete 'organization_id'
    user = User.create(@test_data)
    assert user.new_record?
  end

  # This is how you can notify a person of an item
  def test_notify
    notification_count = users(:ian).notifications.count
    
    # Peter sends Ian a notification about Stephen
    notification = users(:ian).notify_of(people(:stephen), users(:peter))
    
    assert_equal notification_count + 1, users(:ian).notifications.count
    
    assert users(:ian).has_been_notified_of?(people(:stephen))

    # Check that the notifier id was set
    assert_equal users(:peter).id, notification.notifier_id
  end   
  
  # This is how you can look up a notification for an item
  def test_find_notification_for
    # Peter sends Ian a notification about stephen
    users(:ian).notify_of(people(:stephen), users(:peter))

    assert users(:ian).find_notification_for(people(:stephen))
    assert_nil users(:peter).find_notification_for(people(:stephen))
  end
  
  def test_groups_created_after_create
    user = assert_create
    assert user.documents_folder.is_a?(Folder)
    assert user.calendars.first.is_a?(Calendar)
    assert user.contact_list.is_a?(ContactList)
    assert user.bookmark_folder.is_a?(BookmarkFolder)
  end
  
  def test_selected_works
    User.selected= users(:ian)
    assert_equal users(:ian), User.selected
  end
  
  def test_can_edit
    assert users(:ian).can_edit?(joyent_files(:ian_jpg))
    assert users(:ian).can_edit?(joyent_files(:ians_dog_jpg))

    assert !users(:peter).can_edit?(joyent_files(:ian_jpg))
    assert !users(:peter).can_edit?(joyent_files(:ians_dog_jpg))

    assert !users(:jason).can_edit?(joyent_files(:ian_jpg))
    assert !users(:jason).can_edit?(joyent_files(:ians_dog_jpg))
  end

  def test_find_other_users
    User.current         = users(:ian)
    Organization.current = organizations(:joyent)
    
    users = users(:ian).other_users
    assert !users.map(&:id).include?(users(:ian).id)
  end

  # This is how you can comment on an item
  def test_comment_on_item
    comment_count = joyent_files(:ian_jpg).comments.count
    
    # Ian posts a comment about his picture
    comment = users(:ian).comment_on_item(joyent_files(:ian_jpg), 'v. hott!!1')
    
    assert_equal comment_count + 1, joyent_files(:ian_jpg).comments.count
    
    # Check that the commenter id was set
    assert_equal users(:ian).id, comment.user_id
  end                                             
          
  # Regression Test for #3263
  def test_comment_order
    comment1 = users(:ian).comment_on_item(joyent_files(:ians_dog_jpg), 'v. hott!!1') 
    sleep(2)
    comment2 = users(:ian).comment_on_item(joyent_files(:ians_dog_jpg), 'v. hott!!2') 
    sleep(2)
    comment3 = users(:ian).comment_on_item(joyent_files(:ians_dog_jpg), 'v. hott!!3') 

    assert_equal comment1.id, joyent_files(:ians_dog_jpg).comments(true)[0].id
    assert_equal comment2.id, joyent_files(:ians_dog_jpg).comments(true)[1].id
    assert_equal comment3.id, joyent_files(:ians_dog_jpg).comments(true)[2].id
     
    comment1.update_attribute(:body, "another")                 
    comment3.update_attribute(:body, "another")

    assert_equal comment1.id, joyent_files(:ians_dog_jpg).comments(true)[0].id
    assert_equal comment2.id, joyent_files(:ians_dog_jpg).comments(true)[1].id
    assert_equal comment3.id, joyent_files(:ians_dog_jpg).comments(true)[2].id
  end
  
  def test_system_email
    assert_equal "ian@joyent.joyent.com", users(:ian).system_email
  end
  
  def test_notifications
    assert_equal [notifications(:ian_check_it), notifications(:ian_check_this_sweet_list)], users(:ian).current_notifications
  end
  
  def test_contact_list_created
    Organization.current = organizations(:joyent)
    u = assert_create
    u.reload # omg h8
    assert_not_nil u.contact_list
  end
  
  def test_from_addresses
    ians_addresses = EmailAddress.find(:all, :conditions => ['person_id = ?', people(:ian).id])
    
    assert_equal ians_addresses.size + 1, users(:ian).from_addresses.size
  end
  
  def test_from_addresses_include_system_email
    assert users(:ian).from_addresses.include?(users(:ian).system_email)
  end
  
  def test_from_addresses_put_preferred_first
    assert_equal people(:ian).primary_email_cache, users(:ian).from_addresses.first
  end
  
  def test_from_addresses_with_no_preferred_puts_system_email_first
    email_addresses(:ian_at_txd).update_attribute :preferred, false
    assert_equal users(:ian).system_email, users(:ian).from_addresses.first
  end
  
  # regrssion for 2738, 2955
  def test_creating_user_updates_person_with_correct_emails
    o = organizations(:joyent)
    p = people(:stephen)
    u = o.users.create( :username => "stephen",
        :password => "testpass",
        :person_id => p.id,
        :admin => false,
        :identity => Identity.create)
        
    assert u.valid?
    p.reload
    
    assert_equal ["stephen@joyent.joyent.com", "stephen@joyent.net", "stephen@koz.dev.joyent.com"], p.email_addresses.map(&:email_address).sort
    assert_equal "stephen@joyent.joyent.com", p.email_addresses.first.email_address
  end
  
  def test_from_addresses_work_if_email_addresses_is_empty
    people(:ian).email_addresses.clear
    
    assert_equal users(:ian).system_email, users(:ian).from_addresses.first
  end
  
  def test_mail_root_mailboxes
    User.current = users(:ian)
    assert_equal 3, users(:ian).mail_root_mailboxes.size
    
    assert !users(:ian).mail_root_mailboxes.any? { |mb| mb.full_name == 'INBOX' }
    assert !users(:ian).mail_root_mailboxes.any? { |mb| mb.full_name == 'INBOX.Sent' }
    assert !users(:ian).mail_root_mailboxes.any? { |mb| mb.full_name == 'INBOX.Drafts' }
    assert !users(:ian).mail_root_mailboxes.any? { |mb| mb.full_name == 'INBOX.Trash' }
  end
  
  def test_mail_root_mailboxes_gives_empty_array_if_no_roots
    mailboxes(:ian_inbox_concerts_2006).destroy
    mailboxes(:ian_inbox_concerts).destroy
    mailboxes(:ian_delete_me).destroy
    mailboxes(:ian_base).destroy
    
    assert_equal [], users(:ian).mail_root_mailboxes
  end

  def test_destroy_cascades
    uid = users(:ian).id
    [Calendar, Comment, ContactList, Event, Folder, Invitation, JoyentFile, LoginToken, Mailbox, Message, Person, Permission, SmartGroup].each do |c|
      assert c.find_all_by_user_id(uid).length > 0
    end
    assert Notification.find_all_by_notifiee_id(uid).length > 0
    assert Notification.find_all_by_notifier_id(uid).length > 0
    assert Tagging.find_all_by_tagger_id(uid).length > 0
    
    users(:ian).destroy

    [Calendar, Comment, ContactList, Event, Folder, Invitation, JoyentFile, LoginToken, Mailbox, Message, Person, Permission, SmartGroup].each do |c|
      assert_equal 0, c.find_all_by_user_id(uid).length, "#{c.to_s} was not 0"
    end
    assert_equal 0, Notification.find_all_by_notifiee_id(uid).length
    assert_equal 0, Notification.find_all_by_notifier_id(uid).length
    assert_equal 0, Tagging.find_all_by_tagger_id(uid).length
  end

  def test_destroy_doesnt_go_overboard
    uid = users(:ian).id
    all = []
    user = []

    [Calendar, ContactList, Event, Folder, JoyentFile, LoginToken, Mailbox, Message, Person, SmartGroup].each do |c|
      all << c.find(:all).length
      user << c.find_all_by_user_id(uid).length
    end

    all << Comment.find(:all).length
    user << Comment.find_all_by_user_id(uid).length + Comment.find(:all).select{|c| c.user_id != uid && c.commentable.owner.id == uid}.length
    all << Notification.find(:all).length
    user << Notification.find_all_by_notifiee_id(uid).length + Notification.find_all_by_notifier_id(uid).length - Notification.find(:all, :conditions => [ "(notifiee_id = ? AND notifier_id = ?)", uid, uid ]).length
    all << Invitation.find(:all).length
    user << Event.find_all_by_user_id(uid).collect(&:invitations).flatten.length
    all << Permission.find(:all).length
    user << Permission.find_all_by_user_id(uid).length + Permission.find(:all, :conditions => [ "user_id != ?", uid ]).collect(&:item).select{|i| i.owner.id == uid}.length
    all << Tagging.find(:all).length
    user << Tagging.find_all_by_tagger_id(uid).length + Tagging.find(:all, :conditions => ["tagger_id != ?", uid ]).collect(&:taggable).select{|t| t.owner.id == uid}.length

    users(:ian).destroy

    all.reverse!
    user.reverse!
    [Calendar, ContactList, Event, Folder, JoyentFile, LoginToken, Mailbox, Message, Person, SmartGroup, Comment, Notification, Invitation, Permission, Tagging].each do |c|
      assert_equal all.pop - user.pop, c.find(:all).length, "#{c} count mismatch"
    end
  end    
                                                           
  # These are the tests being performed
  # Test:         S-------------E            Result
  #  1            |  [-------]  |            busy           
  #  2     [---]  |             |            !busy
  #  3            |             |  [---]     !busy
  #  4         [--|-------------|--]         busy
  #  5            [-------------]            busy
  #  6            [-------]     |            busy
  #  7            |      [------]            busy
  #  8       [----|---]         |            busy
  #  9            |       [-----|----]       busy
  #  10    [------]             |            !busy
  #  11           |             [------]     !busy
  def test_busy_during_for_non_repeating_events   
    # These events are breaking the tests during certain times of the day
    # so keep only the ones that we want
    users(:ian).events.each{|e| e.destroy unless e.name =~ /busy/}
    
    User.current = users(:ian)
    u = users(:ian)
    e = Event.new
    # test 1       
    e.start_time = Time.now.midnight - 1.minute
    e.end_time   = Time.now.midnight + 1.minute
    assert u.busy_during?(e)

    # test 2
    e.start_time = Time.now.midnight - 25.minutes
    e.end_time   = Time.now.midnight - 20.minutes
    assert !u.busy_during?(e)
    
    # test 3
    e.start_time = Time.now.midnight + 20.minutes
    e.end_time   = Time.now.midnight + 25.minutes
    assert !u.busy_during?(e)
        
    # test 4
    e.start_time = Time.now.midnight - 6.minutes
    e.end_time   = Time.now.midnight + 6.minutes
    assert u.busy_during?(e)
    
    # test 5
    e.start_time = Time.now.midnight - 5.minutes
    e.end_time   = Time.now.midnight + 5.minutes
    assert u.busy_during?(e)
    
    # test 6
    e.start_time = Time.now.midnight - 5.minutes
    e.end_time   = Time.now.midnight + 2.minutes
    assert u.busy_during?(e)
    
    # test 7
    e.start_time = Time.now.midnight - 2.minutes
    e.end_time   = Time.now.midnight + 5.minutes
    assert u.busy_during?(e)
    
    # test 8
    e.start_time = Time.now.midnight - 7.minutes
    e.end_time   = Time.now.midnight - 2.minutes
    assert u.busy_during?(e)
    
    # test 9
    e.start_time = Time.now.midnight + 2.minutes
    e.end_time   = Time.now.midnight + 7.minutes
    assert u.busy_during?(e)
    
    # test 10
    e.start_time = Time.now.midnight - 10.minutes
    e.end_time   = Time.now.midnight - 5.minutes
    assert !u.busy_during?(e)
    
    # test 11
    e.start_time = Time.now.midnight + 5.minutes
    e.end_time   = Time.now.midnight + 10.minutes
    assert !u.busy_during?(e)                                    
  end
  
  def test_busy_during_for_repeating_finite_events 
    User.current = users(:ian)
    u = users(:ian)
    e = Event.new
    e.start_time = Time.now.midnight - 1.minute + 3.days
    e.end_time   = Time.now.midnight + 1.minute + 3.days

    assert u.busy_during?(e)
  end

  def test_busy_during_for_repeating_infinite_events
    User.current = users(:ian)
    u = users(:ian)
    e = Event.new
    e.start_time = Time.now.midnight - 1.minute + 20.days
    e.end_time   = Time.now.midnight + 1.minute + 20.days

    assert u.busy_during?(e)
  end

  def test_no_mailboxes
    u = User.new
    assert_equal [], u.mail_root_mailboxes
  end

  def test_can_edit_user
    User.current = users(:ian)
    assert User.current.can_edit?(users(:ian).person)
  end

  # can't have an association named 'permissions' or else restricted_find will erroneously work
  def test_no_permissions_association
    assert_raise(NoMethodError) {
      users(:ian).permissions
    }
  end

  def test_switch_to
    User.current = users(:ian)
    LoginToken.current = User.current.create_login_token

    assert_equal User.current.switch_to(users(:peter).id), users(:peter)
  end

  def test_invalid_switch_to
    User.current = users(:ian)
    LoginToken.current = User.current.create_login_token

    assert_raise(JoyentExceptions::UserNotConnectedToIdentity) {
      User.current.switch_to(users(:bernard).id)
    }
  end

  def test_connect_other_user
    User.current = users(:ian)
    assert_equal 4, User.current.identity.users.length
    assert_equal 4, Identity.count
    User.current.connect_other_user('joyent.joyent.com', 'bernard', 'testpass')
    
    assert_equal 5, User.current.reload.identity.users.length
    assert_equal 3, Identity.count
  end
  
  def test_invalid_connect_other_user
    User.current = users(:ian)
    assert_equal 4, User.current.identity.users.length
    assert_equal 4, Identity.count
    User.current.connect_other_user('asdf', 'bernard', 'testpass')
    User.current.connect_other_user('joyent.joyent.com', 'asdf', 'testpass')
    User.current.connect_other_user('joyent.joyent.com', 'bernard', 'asdf')

    assert_equal 4, User.current.identity.users(true).length
    assert_equal 4, Identity.count
  end
  
  def test_disconnect_other_user
    User.current = users(:ian)
    assert_equal 8, User.current.subscriptions.count
    assert_equal 4, User.current.identity.users.length
    assert_equal 4, Identity.count
    other_user = users(:peter)
    User.current.disconnect_other_user(other_user)

    assert_equal 3, User.current.identity.users(true).length
    assert_equal 5, Identity.count
    
    assert_equal 2, User.current.subscriptions.count
  end

  def test_invalid_disconnect_other_user
    User.current = users(:ian)
    assert_equal 4, User.current.identity.users.length
    assert_equal 4, Identity.count
    other_user = users(:bernard)
    User.current.disconnect_other_user(other_user)

    assert_equal 4, User.current.identity.users(true).length
    assert_equal 4, Identity.count
  end
  
  def test_user_subscribed_to_calendar
    User.current = users(:jason)
    assert_equal User.current.id, User.current.subscriptions_to_group_type('Calendar').first.user_id
  end
  
  # TODO commented out until i get set euid, etc. in MockFS
  # def test_ssh_public_keys
  #   user = users(:ian)
  #   
  #   user.add_ssh_public_key('yes')
  #   assert_equal ['yes'], user.send(:read_authorized_keys)
  #   
  #   user.add_ssh_public_key('no')
  #   assert_equal ['yes', 'no'], user.send(:read_authorized_keys)
  #   
  #   user.add_ssh_public_key('no')
  #   assert_equal ['yes', 'no'], user.send(:read_authorized_keys)
  #   
  #   user.remove_ssh_public_key('no')
  #   assert_equal ['yes'], user.send(:read_authorized_keys)
  #   
  #   user.remove_ssh_public_key('yes')
  #   assert_equal [], user.send(:read_authorized_keys)
  # end
  
  def test_language
    User.current = user = users(:ian)
    
    user.set_option('Language', 'en')
    assert_equal 'en', user.language
    user.set_option('Language', 'es')
    assert_equal 'es', user.language
    user.set_option('Language', 'jp')
    assert_equal 'en', user.language
  end
end