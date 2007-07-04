=begin #(fold)
Copyright 2004-2007 Joyent Inc.

Redistribution and/or modification of this code is governed
by either the GPLv2 or Joyent Commercial Software licenses.

Report issues and contribute at http://dev.joyent.com/

$Id$
=end #(end)

ActionController::Routing::Routes.draw do |map|
  map.resources :services

  map.with_options :controller => 'authenticate' do |m|
    m.login                 'login',                 :action => 'login'
    m.logout                'logout',                :action => 'logout'
    m.reset_password        'reset_password',        :action => 'reset_password'
    m.verify_reset_password 'verify_reset_password', :action => 'verify_reset_password'
    m.affiliate_login       'partner/:affiliate',    :action => 'affiliate_login'
  end

  # application home pages
  map.with_options(:controller => 'authenticated', :action => 'home') do |m|
    m.connector_home 'home'
    m.connect_home   'home/connect'
    m.mail_home      'home/mail'
    m.calendar_home  'home/calendar'
    m.people_home    'home/people'
    m.files_home     'home/files'
    m.bookmarks_home 'home/bookmarks'
    m.lists_home     'home/lists'
    m.lightning_home 'home/fileswpl'
  end

  map.with_options :controller => 'admin' do |m|
    m.heartbeat 'heartbeat', :action => 'heartbeat'
  end

  map.with_options :controller => 'user' do |m|
    m.user_switch          'user/switch/:id',           :action => 'switch'
    m.user_connect         'user/connect',              :action => 'connect'
    m.user_disconnect      'user/disconnect',           :action => 'disconnect'
    m.reset_guest_password 'user/reset_guest_password', :action => 'reset_guest_password'
  end

  map.with_options :controller => 'guest' do |m|
    m.guest_edit 'guest/edit/:id', :action => 'edit', :requirements => {:id => /\d+/}
  end

  map.with_options :controller => 'connect' do |m|
    m.connect_notifications     'connect/notifications',       :action => 'notifications'
    m.connect_search            'connect/search',              :action => 'search'
    m.connect_smart_list        'connect/:smart_group_id',     :action => 'smart_list',       :requirements => {:smart_group_id => /s\d+/}
    m.recent_comments_report    'connect/recent_comments/:id', :action => 'recent_comments'
    m.lightning_portal          'lightning_portal',            :action => 'lightning_portal'
  end     
  
  map.with_options :controller => 'reports' do |m|
    m.reports_create           'connect/create_report/:report_description_id/:reportable_id', :action => 'create',  :requirements => {:report_description_id => /\d+/, :reportable_id => /\d+/}
    m.reports_index            'connect/workspace',                                           :action => 'index'
    m.reports_show             'connect/report/:id',                                          :action => 'show',    :requirements => {:id => /\d+/}
    m.reports_show_by_desc     'connect/report/:report_description_id/:reportable_id',        :action => 'show',    :requirements => {:report_description_id => /\d+/, :reportable_id => /\d+/}
    m.reports_destroy          'connect/remove_report/:id',                                   :action => 'destroy', :requirements => {:id => /\d+/}
    m.reports_destroy_by_desc  'connect/remove_report/:report_description_id/:reportable_id', :action => 'destroy', :requirements => {:report_description_id => /\d+/, :reportable_id => /\d+/}
    m.reports_reorder          'connect/reorder_reports',                                     :action => 'reorder'         
  end

  map.with_options :controller => 'mail' do |m|
    m.mail_compose             'mail/compose',                   :action => 'compose'
    m.mail_unavailable         'mail/unavailable',               :action => 'unavailable'
    m.mail_notifications       'mail/notifications',             :action => 'notifications'
    m.mail_message_move        'mail/move',                      :action => 'move'
    m.mail_message_copy        'mail/copy',                      :action => 'copy'
    m.mail_send_compose        'mail/send',                      :action => 'send_compose'
    m.mail_empty_trash         'mail/empty_trash',               :action => 'empty_trash'
    m.mail_address_lookup      'mail/addresses_for_lookup',      :action => 'addresses_for_lookup'
    m.mail_inbox_unread_count  'mail/inbox_unread_count',        :action => 'inbox_unread_count'
    m.mail_set_sort_order      'mail/set_sort_order',            :action => 'set_sort_order'       
    m.mail_quick_contact       'mail/quick_contact',             :action => 'quick_contact'
    m.mail_rename_mailbox      'mail/rename_group/:id',          :action => 'rename_group',        :requirements => {:id => /\d+/} # hax
    m.mail_delete_mailbox      'mail/reparent_group/:id',        :action => 'reparent_group',      :requirements => {:id => /\d+/} # hax
    m.mail_delete_mailbox      'mail/delete_group/:id',          :action => 'delete_group',        :requirements => {:id => /\d+/} # hax
    m.mail_children_groups     'mail/children_groups/:id',       :action => 'children_groups',     :requirements => {:id => /\d+/} # hax
    m.mail_others_groups       'mail/others_groups',             :action => 'others_groups'
    m.mail_send_reply_to       'mail/send/reply/:id',            :action => 'send_reply_to'
    m.mail_send_forward        'mail/send/forward/:id',          :action => 'send_forward'
    m.mail_send_draft          'mail/send/draft/:id',            :action => 'send_draft'
    m.mail_show_body           'mail/show_body/:id',             :action => 'show_body'
    m.mail_create_mailbox      'mail/create_mailbox',            :action => 'create_mailbox'
    m.mail_attachment          'mail/attachment/:message/:id',   :action => 'attachment'
    m.mail_inline              'mail/inline/:message/:id',       :action => 'inline'
    m.mail_message_delete      'mail/delete',                    :action => 'delete'
    m.mail_mailbox             'mail/mailbox/:id',               :action => 'list',                :requirements => {:id => /\d+/}
    m.mail_special_list        'mail/mailbox/:id',               :action => 'special_list'
    m.mail_unread_messages     'mail/unread_messages/:id',       :action => 'unread_messages'
    m.mail_smart_list          'mail/smart/:smart_group_id',     :action => 'smart_list'
    m.mail_reply               'mail/reply/:id',                 :action => 'reply_to'
    m.mail_forward             'mail/forward/:id',               :action => 'forward'
    m.mail_message_show        'mail/:mailbox/:id',              :action => 'show',                :requirements => {:mailbox => /\d+/}
    m.mail_smart_show          'mail/:smart_group_id/:id',       :action => 'smart_show',          :requirements => {:smart_group_id => /s\d+/}
    m.mail_edit_draft          'mail/drafts/:id',                :action => 'edit_draft'
    m.mail_special_show        'mail/:mailbox/:id',              :action => 'special_show'
    m.message_flag             'message/:id/flag',               :action => 'flag',                :requirements => {:id => /\d+/}
    m.message_unflag           'message/:id/unflag',             :action => 'unflag',              :requirements => {:id => /\d+/}
    m.message_report_issue     'message/issue/:id',              :action => 'report_issue'
  end

  map.with_options :controller => 'lists' do |m|
#    m.lists_create        'lists/create',         :action => 'create'    
#    m.lists_index         'lists/:group',         :action => 'list'
#    m.lists_delete        'lists/delete',         :action => 'delete'
#    m.lists_all           'lists/all',            :action => 'all'
    m.lists_notifications  'lists/notifications',  :action => 'notifications'
    m.list_import          'lists/import',         :action => 'import'
    m.move_list            'lists/move',           :action => 'move'
    m.copy_list            'lists/copy',           :action => 'copy'
    m.lists_set_sort_order 'lists/set_sort_order', :action => 'set_sort_order'

#    m.lists_list_route    'lists/:group_id',      :action => 'list',  :requirements => {:group_id => /\d+/}
#    m.lists_show_route    'lists/:group_id/:id',  :action => 'show',  :requirements => {:group_id => /\d+/}
#    m.lists_show_route2   'lists/all/:id',        :action => 'show' # XXX total lame hack
#    m.lists_peek          'lists/peek/:id',       :action => 'peek'

#    m.lists_smart_list    'lists/:smart_group_id',            :action => 'smart_list',   :requirements => {:smart_group_id => /s\d+/}
#    m.lists_smart_delete  'lists/:smart_group_id/delete',     :action => 'smart_delete', :requirements => {:smart_group_id => /s\d+/}
#    m.lists_smart_show    'lists/:smart_group_id/:id',        :action => 'smart_show',   :requirements => {:smart_group_id => /s\d+/}
#    m.lists_smart_edit    'lists/:smart_group_id/:id/edit',   :action => 'smart_edit',   :requirements => {:smart_group_id => /s\d+/}
  end
  map.resources :lists
  map.resources :list_rows
  map.with_options :controller => 'list_rows' do |m|
    m.list_rows_expand   'list_rows/expand/:id',   :action => 'expand'
    m.list_rows_collapse 'list_rows/collapse/:id', :action => 'collapse'
  end
  map.resources :list_columns
  map.resources :list_cells
  map.resources :list_folders

  map.with_options :controller => 'calendar' do |m|
    m.calendar_create_on_calendar   'calendar/create/:calendar_id',         :action => 'create',         :requirements => {:calendar_id => /\d+/}
    m.calendar_create               'calendar/create',                      :action => 'create'
    m.calendar_import               'calendar/import',                      :action => 'import'
    m.calendar_add_overlay          'calendar/add_overlay/:user_id',        :action => 'add_overlay',    :requirements => {:user_id => /\d+/}
    m.calendar_remove_overlay       'calendar/remove_overlay/:user_id',     :action => 'remove_overlay', :requirements => {:user_id => /\d+/}
    m.calendar_create_calendar      'calendar/create_calendar',             :action => 'create_calendar'
    m.calendar_event_delete         'calendar/events/delete',               :action => 'delete'
    m.calendar_event_move           'calendar/events/move',                 :action => 'move'
    m.calendar_event_copy           'calendar/events/copy',                 :action => 'copy'
    m.calendar_notifications        'calendar/notifications',               :action => 'notifications'

    m.calendar_list_route           'calendar/:calendar_id/list',           :action => 'list',           :requirements => {:calendar_id => /\d+/}
    m.calendar_month_route          'calendar/:calendar_id/month',          :action => 'month',          :requirements => {:calendar_id => /\d+/}
    m.calendar_day_route            'calendar/:calendar_id/day',            :action => 'day',            :requirements => {:calendar_id => /\d+/}
    m.calendar_show_route           'calendar/:calendar_id/:id',            :action => 'show',           :requirements => {:calendar_id => /\d+/}
    m.calendar_edit_route           'calendar/:calendar_id/:id/edit',       :action => 'edit',           :requirements => {:calendar_id => /\d+/}
    
    m.calendar_todays_events        'calendar/todays_events/:id',           :action => 'todays_events'
    m.calendar_weeks_events         'calendar/weeks_events/:id',            :action => 'weeks_events'
    
    m.calendar_all_list             'calendar/all/list',                    :action => 'all_list'
    m.calendar_all_month            'calendar/all/month',                   :action => 'all_month'
    m.calendar_all_day              'calendar/all/day',                     :action => 'all_day'
    m.calendar_all_show             'calendar/all/:id',                     :action => 'all_show'
    m.calendar_all_edit             'calendar/all/:id/edit',                :action => 'all_edit'

    m.calendar_invitations_accept   'calendar/invitations/:id/accept',      :action => 'invitations_accept'
    m.calendar_invitations_decline  'calendar/invitations/:id/decline',     :action => 'invitations_decline'
    
    m.calendar_smart_list           'calendar/:smart_group_id/list',        :action => 'smart_list',   :requirements => {:smart_group_id => /s\d+/}
    m.calendar_smart_month          'calendar/:smart_group_id/month',       :action => 'smart_month',  :requirements => {:smart_group_id => /s\d+/}
    m.calendar_smart_day            'calendar/:smart_group_id/day',         :action => 'smart_day',    :requirements => {:smart_group_id => /s\d+/}
    m.calendar_smart_show           'calendar/:smart_group_id/:id',         :action => 'smart_show',   :requirements => {:smart_group_id => /s\d+/}
    m.calendar_smart_edit           'calendar/:smart_group_id/:id/edit',    :action => 'smart_edit',   :requirements => {:smart_group_id => /s\d+/}
  end

  map.with_options :controller => 'people' do |m|
    m.people_copy            'people/copy',                :action => 'copy'
    m.people_move            'people/move',                :action => 'move'
    m.people_delete          'people/delete',              :action => 'delete'
    m.people_delete_confirm  'people/delete_confirm',      :action => 'delete_confirm'
    m.people_import          'people/import',              :action => 'import'
    m.people_call            'people/call',                :action => 'call'
    m.people_call_list       'people/call_list',           :action => 'call_list'
    m.people_jajah_info      'people/jajah_info',          :action => 'get_jajah_info'
    m.people_set_sort_order  'people/set_sort_order',      :action => 'set_sort_order'
    m.people_others_groups   'people/others_groups',       :action => 'others_groups'
    m.people_children_groups 'people/children_groups/:id', :action => 'children_groups', :requirements => {:id => /\d+/}
    m.people_add_field       'people/:action',                                           :requirements => {:action => /add_\w+/}
    m.people_notifications   'people/notifications',       :action => 'notifications'
                                                                                                        
    m.current_time_report   'people/current_time/:id', :action => 'current_time'
    
    m.people_list           'people/:group',         :action => 'list'
    m.people_vcards         'people/:group/vcards',  :action => 'vcards'

    m.person_create         'person/create',         :action => 'create'
    m.person_show           'person/:id',            :action => 'show',  :requirements => {:id => /\d+/}
    m.person_edit           'person/:id/edit',       :action => 'edit',  :requirements => {:id => /\d+/}
    m.person_icon           'person/:id/icon',       :action => 'icon',  :requirements => {:id => /\d+/}
    m.person_vcard          'person/:id/vcard',      :action => 'vcard', :requirements => {:id => /\d+/}
  end

  map.with_options :controller => 'files' do |m|
    m.files_move                       'files/move',                                            :action => 'move'
    m.files_strongspace_move           'files/strongspace_move',                                :action => 'strongspace_move'
    m.files_copy                       'files/copy',                                            :action => 'copy'
    m.files_strongspace_copy           'files/strongspace_copy',                                :action => 'strongspace_copy'
    m.files_notifications              'files/notifications',                                   :action => 'notifications'
    m.files_strongspace                'files/strongspace',                                     :action => 'strongspace'
    m.files_strongspace_show           'files/strongspace/show/:owner_id/*path',                :action => 'strongspace_show'
    m.files_strongspace_list           'files/strongspace/:owner_id/*path',                     :action => 'strongspace'
    m.file_strongspace_download        'files/strongspacedownload/:owner_id/*path',             :action => 'strongspace_download'
    m.file_strongspace_delete_group    'files/delete_strongspace_group/*path',                  :action => 'delete_strongspace_group'
    m.files_service                    'files/service/:service_name',                           :action => 'service'
    m.files_service_show               'files/service/:service_name/show/:file_id',             :action => 'service_show'
    m.files_service_list               'files/service/:service_name/:group_id',                 :action => 'service'
    m.files_service_download           'files/servicedownload/:service_name/:file_id',          :action => 'service_download'
    m.files_delete                     'files/delete',                                          :action => 'delete'
    m.files_strongspace_delete         'files/strongspace_delete',                              :action => 'strongspace_delete'
    m.files_create                     'files/create/:folder_id',                               :action => 'create',       :requirements => {:folder_id => /\d+/}
    m.files_strongspace_create         'files/strongspace_create/*path',                        :action => 'strongspace_create'
    m.files_strongpsace_guest_access   'files/set_guest_access/*path',                          :action => 'set_guest_access'
                                       
    m.strongspace_children_groups      'files/strongspace_children_groups/*path',               :action => 'strongspace_children_groups'
    m.service_children_groups          'files/service_children_groups/:service_name/:group_id', :action => 'service_children_groups'
    m.files_strongspace_list_route     'files/strongspace_list/*path',                          :action => 'strongspace'
    m.files_list_route                 'files/:folder_id',                                      :action => 'list',         :requirements => {:folder_id => /\d+/}
    m.files_delete_route               'files/:folder_id/delete',                               :action => 'delete',       :requirements => {:folder_id => /\d+/} 
    m.files_show_route                 'files/:folder_id/:id',                                  :action => 'show',         :requirements => {:folder_id => /\d+/}
    m.files_edit_route                 'files/:folder_id/:id/edit',                             :action => 'edit',         :requirements => {:folder_id => /\d+/}
    m.files_strongspace_edit           'files/strongspace_edit/:owner_id/*path',                :action => 'strongspace_edit'
                                       
    m.files_smart_list                 'files/:smart_group_id',                                 :action => 'smart_list',   :requirements => {:smart_group_id => /s\d+/}
    m.files_smart_show                 'files/:smart_group_id/:id',                             :action => 'smart_show',   :requirements => {:smart_group_id => /s\d+/}
    m.files_smart_edit                 'files/:smart_group_id/:id/edit',                        :action => 'smart_edit',   :requirements => {:smart_group_id => /s\d+/}
                                                                                                
    m.file_download                    'files/download/:id',                                    :action => 'download'
    m.file_download_inline             'files/download_inline/:id',                             :action => 'download_inline'
    m.file_strongspace_download_inline 'files/strongspace_inline/:owner_id/*path',              :action => 'strongspace_download_inline'
    m.file_service_download_inline     'files/service_inline/:service_name/:file_id',           :action => 'service_download_inline', :requirements => {:file_id => /.+/}
  end
  map.file_create               'files/create',                     :controller => 'files', :action => 'create' # doesn't work in with_options

  map.with_options :controller => 'bookmarks' do |m|
    m.bookmarks_move          'bookmarks/move',                :action => 'move'
    m.bookmarks_copy          'bookmarks/copy',                :action => 'copy'
    m.bookmarks_notifications 'bookmarks/notifications',       :action => 'notifications'
    m.bookmarks_everyone      'bookmarks/everyone',            :action => 'list_everyone'
    m.bookmarks_delete        'bookmarks/delete',              :action => 'delete'
    m.bookmarks_create        'bookmarks/create',              :action => 'create'
    m.bookmarks_show          'bookmarks/:id/show',            :action => 'show',       :requirements => {:id => /\d+/}
                                                              
    m.bookmarks_list_route    'bookmarks/:bookmark_folder_id', :action => 'list',       :requirements => {:bookmark_folder_id => /\d+/}
    m.bookmarks_delete_route  'bookmarks/delete',              :action => 'delete',     :requirements => {:bookmark_folder_id => /\d+/} 
    m.bookmarks_edit_route    'bookmarks/:id/edit',            :action => 'edit',       :requirements => {:id => /\d+/}
                                                                                        
    m.bookmarks_smart_list    'bookmarks/:smart_group_id',     :action => 'smart_list', :requirements => {:smart_group_id => /s\d+/}
  end

  map.with_options :controller => 'comments' do |m|
    m.comment_add    'comments/add/:id',    :action => 'add'
    m.comment_delete 'comments/delete/:id', :action => 'remove'
    m.comment_edit   'comments/edit/:id',   :action => 'edit'
  end

  # These routes are for use within feeds etc.   They represent the 'official' URL for the item
  map.external_message_show  'syndicate/mail/external/show/:id',  :action=>'external_show', :controller=>'mail'
  map.external_event_show    'syndicate/calendar/show/:id',       :action=>'external_show', :controller=>'calendar'
  map.external_person_show   'syndicate/people/show/:id',         :action=>'external_show', :controller=>'people'
  map.external_file_show     'syndicate/file/show/:id',           :action=>'external_show', :controller=>'files'
  map.external_bookmark_show 'syndicate/bookmark/show/:id',       :action=>'external_show', :controller=>'bookmarks'
 
  map.with_options :controller => 'syndication' do |m|
    m.connect_smart_rss             'syndicate/connect/:smart_group_id/rss',    :action => 'connect_smart_rss',         :requirements => {:smart_group_id => /s\d+/}
    m.connect_notifications_rss     'syndicate/connect/notifications/rss',      :action => 'connect_notifications_rss'
   
    m.current_time_report_rss       'syndicate/connect/current_time/:id/rss',      :action => 'current_time_rss', :requirements => {:id => /\d+/}
    m.recent_comments_report_rss    'syndicate/connect/recent_comments/:id/rss',   :action => 'recent_comments_rss', :requirements => {:id => /\d+/}
    m.mail_unread_messages_rss      'syndicate/connect/unread_messages/:id/rss',   :action => 'unread_messages_rss', :requirements => {:id => /\d+/}
    m.calendar_todays_events_rss    'syndicate/connect/todays_events/:id/rss',     :action => 'todays_events_rss',   :requirements => {:id => /\d+/}
    m.calendar_weeks_events_rss     'syndicate/connect/weeks_events/:id/rss',      :action => 'weeks_events_rss',    :requirements => {:id => /\d+/}
    
    m.reports_show_rss              'syndicate/connect/report/:id',                                   :action => 'reports_rss',       :requirements => {:id => /\d+/}
    m.reports_show_by_desc_rss      'syndicate/connect/report/:report_description_id/:reportable_id', :action => 'reports_rss',       :requirements => {:report_description_id => /\d+/, :reportable_id => /\d+/}
  
    m.tag_rss                       'syndicate/tag/:tag_name/rss',              :action => 'tag_rss'
    
    m.mail_mailbox_rss              'syndicate/mail/mailbox/:id/rss',           :action => 'mail_mailbox_rss'
    m.mail_smart_rss                'syndicate/mail/smart/:smart_group_id/rss', :action => 'mail_smart_rss',            :requirements => {:smart_group_id => /s\d+/}
    m.mail_notifications_rss        'syndicate/mail/notifications/rss',         :action => 'mail_notifications_rss'

    m.calendar_smart_ics            'syndicate/calendar/:smart_group_id/ics',   :action => 'smart_calendar_ics',        :requirements => {:smart_group_id => /s\d+/}
    m.calendar_smart_rss            'syndicate/calendar/:smart_group_id/rss',   :action => 'smart_calendar_rss',        :requirements => {:smart_group_id => /s\d+/}
    m.calendar_invitations_ics      'syndicate/calendar/invitations/ics',       :action => 'invitations_calendar_ics'
    m.calendar_notifications_ics    'syndicate/calendar/notifications/ics',     :action => 'notifications_calendar_ics'
    m.calendar_all_ics              'syndicate/calendar/all/ics',               :action => 'all_calendar_ics'
    m.calendar_rss                  'syndicate/calendar/:calendar_id/rss',      :action => 'standard_calendar_rss',     :requirements => {:calendar_id => /\d+/}
    m.calendar_ics                  'syndicate/calendar/:calendar_id/ics',      :action => 'standard_calendar_ics',     :requirements => {:calendar_id => /\d+/}
    m.calendar_all_rss              'syndicate/calendar/all/rss',               :action => 'all_calendar_rss'
    m.calendar_notifications_rss    'syndicate/calendar/notifications/rss',     :action => 'notifications_calendar_rss'
    m.calendar_invitations_rss      'syndicate/calendar/invitations/rss',       :action => 'invitations_calendar_rss'
                                                                             
    m.people_rss                    'syndicate/people/:group/rss',              :action => 'people_rss'

    m.files_rss                     'syndicate/files/:folder_id/rss',           :action => 'files_standard_rss',        :requirements => {:folder_id => /\d+/}  
    m.files_smart_rss               'syndicate/files/:smart_group_id/rss',      :action => 'files_smart_rss',           :requirements => {:smart_group_id => /s\d+/} 
    m.files_notifications_rss       'syndicate/files/notifications/rss',        :action => 'files_notifications_rss'
    m.files_strongspace_rss         'syndicate/files/strongspace/*path/rss',    :action => 'files_strongspace_rss'
    m.files_service_rss             'syndicate/files/service/:service_name/:group_id/rss',:action => 'files_service_rss'
        
    m.bookmarks_rss                 'syndicate/bookmarks/:bookmark_folder_id/rss', :action => 'bookmarks_list_rss',      :requirements => {:bookmark_folder_id => /\d+/}
    m.bookmarks_everyone_rss        'syndicate/bookmarks/everyone/rss',         :action => 'bookmarks_list_everyone_rss'
    m.bookmarks_notifications_rss   'syndicate/bookmarks/notifications/rss',    :action => 'bookmarks_notifications_rss'
    m.bookmarks_smart_group_rss     'syndicate/bookmarks/:smart_group_id/rss',  :action => 'bookmarks_smart_list_rss',   :requirements => {:smart_group_id => /s\d+/}

    m.lists_standard_rss            'syndicate/lists/:group_id/rss',            :action => 'lists_standard_rss',        :requirements => {:group_id => /\d+/}  
    m.lists_smart_rss               'syndicate/lists/:smart_group_id/rss',      :action => 'lists_smart_rss',           :requirements => {:smart_group_id => /s\d+/} 
    m.lists_notifications_rss       'syndicate/lists/notifications/rss',        :action => 'lists_notifications_rss'
  end

  map.with_options :controller=>'api' do |m|
    m.connect 'api/organizations', :action=>'create_organization'
    m.connect 'api/organizations/:id', :action=>'organization_dispatch'
    m.connect 'api/organizations/:id/domains', :action=>"create_domain"
    m.connect 'api/organizations/:id/domains/:domain_id', :action=>"domain_dispatch"
  end

  map.with_options :controller => 'smart_group' do |m|
    m.smart_group_create 'smart_group/create',     :action => 'create'
    m.smart_group_rename 'smart_group/rename/:id', :action => 'rename'
    m.smart_group_update 'smart_group/update/:id', :action => 'update'
  end
  
  map.with_options :controller => 'subscriptions' do |m|
    m.subscription_list       'subscriptions/',              :action => 'list'
    m.subscription_create     'subscriptions/create',        :action => 'subscribe'
    m.subscription_delete     'subscriptions/delete',        :action => 'unsubscribe'
  end
  
  map.with_options :controller => 'browser' do |m|
    m.browse_list     'browser/',             :action => 'list'
    m.browse_column   'browser/column/:type', :action => 'column'
  end

  # Authkey
  map.connect 'authenticate/key', :controller => 'auth_key', :action => 'key'

  # Install the default route as the lowest priority.
  map.connect ':controller/:action/:id.:format'
  map.connect ':controller/:action/:id'

  # Heartbeat
  map.connect 'heartbeat/index', :controller => 'heartbeat', :action => 'index'
  
  
  # catchall
  map.connect '*path', :controller => 'connect', :action => 'index'
end