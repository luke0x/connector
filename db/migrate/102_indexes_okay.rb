=begin #(fold)
++
Copyright 2004-2007 Joyent Inc.

Redistribution and/or modification of this code is 
governed by the GPLv2.

Report issues and contribute at http://dev.joyent.com/

$Id$
--
=end #(end)

# indexes, okay

class IndexesOkay < ActiveRecord::Migration
  def self.up
    add_index "addresses", ["person_id"], :name => "addresses_person_id_index" rescue nil
    add_index "bookmark_folders", ["user_id"], :name => "bookmark_folders_user_id_index" rescue nil
    add_index "bookmarks", ["organization_id"], :name => "bookmarks_organization_id_index" rescue nil
    add_index "bookmarks", ["user_id"], :name => "bookmarks_user_id_index" rescue nil
    add_index "bookmarks", ["bookmark_folder_id"], :name => "bookmarks_bookmark_folder_id_index" rescue nil
    add_index "bookmarks", ["uri_sha1"], :name => "bookmarks_uri_sha1_index" rescue nil
    add_index "calendars", ["user_id"], :name => "calendars_user_id_index" rescue nil
    add_index "calendars", ["parent_id"], :name => "calendars_parent_id_index" rescue nil
    add_index "comments", ["user_id"], :name => "comments_user_id_index" rescue nil
    add_index "comments", ["commentable_id"], :name => "comments_commentable_id_index" rescue nil
    add_index "comments", ["commentable_type"], :name => "comments_commentable_type_index" rescue nil
    add_index "contact_lists", ["user_id"], :name => "contact_lists_user_id_index" rescue nil
    add_index "domains", ["organization_id"], :name => "domains_organization_id_index" rescue nil
    add_index "domains", ["web_domain"], :name => "domains_web_domain_index" rescue nil
    add_index "email_addresses", ["person_id"], :name => "email_addresses_person_id_index" rescue nil
    add_index "events", ["organization_id"], :name => "events_organization_id_index" rescue nil
    add_index "events", ["user_id"], :name => "events_user_id_index" rescue nil
    add_index "folders", ["user_id"], :name => "folders_user_id_index" rescue nil
    add_index "folders", ["parent_id"], :name => "folders_parent_id_index" rescue nil
    add_index "im_addresses", ["person_id"], :name => "im_addresses_person_id_index" rescue nil
    add_index "invitations", ["event_id"], :name => "invitations_event_id_index" rescue nil
    add_index "invitations", ["user_id"], :name => "invitations_user_id_index" rescue nil
    add_index "invitations", ["calendar_id"], :name => "invitations_calendar_id_index" rescue nil
    add_index "joyent_files", ["organization_id"], :name => "joyent_files_organization_id_index" rescue nil
    add_index "joyent_files", ["user_id"], :name => "joyent_files_user_id_index" rescue nil
    add_index "joyent_files", ["folder_id"], :name => "joyent_files_folder_id_index" rescue nil
    add_index "login_tokens", ["value"], :name => "login_tokens_value_index" rescue nil
    add_index "mailboxes", ["uid_validity"], :name => "mailboxes_uid_validity_index" rescue nil
    add_index "mailboxes", ["uid_next"], :name => "mailboxes_uid_next_index" rescue nil
    add_index "mailboxes", ["parent_id"], :name => "mailboxes_parent_id_index" rescue nil
    add_index "mailboxes", ["user_id"], :name => "mailboxes_user_id_index" rescue nil
    add_index "messages", ["organization_id"], :name => "messages_organization_id_index" rescue nil
    add_index "messages", ["user_id"], :name => "messages_user_id_index" rescue nil
    add_index "messages", ["mailbox_id"], :name => "messages_mailbox_id_index" rescue nil
    add_index "messages", ["uid"], :name => "messages_uid_index" rescue nil
    add_index "notifications", ["organization_id"], :name => "notifications_organization_id_index" rescue nil
    add_index "notifications", ["notifiee_id"], :name => "notifications_notifiee_id_index" rescue nil
    add_index "notifications", ["notifier_id"], :name => "notifications_notifier_id_index" rescue nil
    add_index "notifications", ["item_id"], :name => "notifications_item_id_index" rescue nil
    add_index "notifications", ["item_type"], :name => "notifications_item_type_index" rescue nil
    add_index "people", ["organization_id"], :name => "people_organization_id_index" rescue nil
    add_index "people", ["user_id"], :name => "people_user_id_index" rescue nil
    add_index "people", ["contact_list_id"], :name => "people_contact_list_id_index" rescue nil
    add_index "permissions", ["user_id"], :name => "permissions_user_id_index" rescue nil
    add_index "permissions", ["item_id"], :name => "permissions_item_id_index" rescue nil
    add_index "permissions", ["item_type"], :name => "permissions_item_type_index" rescue nil
    add_index "phone_numbers", ["person_id"], :name => "phone_numbers_person_id_index" rescue nil
    add_index "quotas", ["organization_id"], :name => "quotas_organization_id_index" rescue nil
    add_index "report_descriptions", ["name"], :name => "report_descriptions_name_index" rescue nil
    add_index "reports", ["report_description_id"], :name => "reports_report_description_id_index" rescue nil
    add_index "reports", ["reportable_id"], :name => "reports_reportable_id_index" rescue nil
    add_index "reports", ["reportable_type"], :name => "reports_reportable_type_index" rescue nil
    add_index "reports", ["organization_id"], :name => "reports_organization_id_index" rescue nil
    add_index "reports", ["user_id"], :name => "reports_user_id_index" rescue nil
    add_index "smart_group_attribute_descriptions", ["smart_group_description_id"], :name => "smart_group_attribute_descriptions_smart_group_description_id_index" rescue nil
    add_index "smart_group_attributes", ["smart_group_id"], :name => "smart_group_attributes_smart_group_id_index" rescue nil
    add_index "smart_group_attributes", ["smart_group_attribute_description_id"], :name => "smart_group_attributes_smart_group_attribute_description_id_index" rescue nil
    add_index "smart_group_descriptions", ["name"], :name => "smart_group_descriptions_name_index" rescue nil
    add_index "smart_group_descriptions", ["item_type"], :name => "smart_group_descriptions_item_type_index" rescue nil
    add_index "smart_groups", ["smart_group_description_id"], :name => "smart_groups_smart_group_description_id_index" rescue nil
    add_index "smart_groups", ["user_id"], :name => "smart_groups_user_id_index" rescue nil
    add_index "special_dates", ["person_id"], :name => "special_dates_person_id_index" rescue nil
    add_index "taggings", ["tag_id"], :name => "taggings_tag_id_index" rescue nil
    add_index "taggings", ["tagger_id"], :name => "taggings_tagger_id_index" rescue nil
    add_index "taggings", ["taggable_id"], :name => "taggings_taggable_id_index" rescue nil
    add_index "taggings", ["taggable_type"], :name => "taggings_taggable_type_index" rescue nil
    add_index "tags", ["name"], :name => "tags_name_index" rescue nil
    add_index "tags", ["organization_id"], :name => "tags_organization_id_index" rescue nil
    add_index "user_options", ["user_id"], :name => "user_options_user_id_index" rescue nil
    add_index "user_options", ["key"], :name => "user_options_key_index" rescue nil
    add_index "user_requests", ["user_id"], :name => "user_requests_user_id_index" rescue nil
    add_index "users", ["person_id"], :name => "users_person_id_index" rescue nil
    add_index "users", ["username"], :name => "users_username_index" rescue nil
    add_index "users", ["organization_id"], :name => "users_organization_id_index" rescue nil
    add_index "users", ["documents_id"], :name => "users_documents_id_index" rescue nil
    add_index "websites", ["person_id"], :name => "websites_person_id_index" rescue nil
  end

  def self.down
    remove_index "addresses", "person_id" rescue nil
    remove_index "bookmark_folders", "user_id" rescue nil
    remove_index "bookmarks", "organization_id" rescue nil
    remove_index "bookmarks", "user_id" rescue nil
    remove_index "bookmarks", "bookmark_folder_id" rescue nil
    remove_index "bookmarks", "uri_sha1" rescue nil
    remove_index "calendars", "user_id" rescue nil
    remove_index "calendars", "parent_id" rescue nil
    remove_index "comments", "user_id" rescue nil
    remove_index "comments", "commentable_id" rescue nil
    remove_index "comments", "commentable_type" rescue nil
    remove_index "contact_lists", "user_id" rescue nil
    remove_index "domains", "organization_id" rescue nil
    remove_index "domains", "web_domain" rescue nil
    remove_index "email_addresses", "person_id" rescue nil
    remove_index "events", "organization_id" rescue nil
    remove_index "events", "user_id" rescue nil
    remove_index "folders", "user_id" rescue nil
    remove_index "folders", "parent_id" rescue nil
    remove_index "im_addresses", "person_id" rescue nil
    remove_index "invitations", "event_id" rescue nil
    remove_index "invitations", "user_id" rescue nil
    remove_index "invitations", "calendar_id" rescue nil
    remove_index "joyent_files", "organization_id" rescue nil
    remove_index "joyent_files", "user_id" rescue nil
    remove_index "joyent_files", "folder_id" rescue nil
    remove_index "login_tokens", "value" rescue nil
    remove_index "mailboxes", "uid_validity" rescue nil
    remove_index "mailboxes", "uid_next" rescue nil
    remove_index "mailboxes", "parent_id" rescue nil
    remove_index "mailboxes", "user_id" rescue nil
    remove_index "messages", "organization_id" rescue nil
    remove_index "messages", "user_id" rescue nil
    remove_index "messages", "mailbox_id" rescue nil
    remove_index "messages", "uid" rescue nil
    remove_index "notifications", "organization_id" rescue nil
    remove_index "notifications", "notifiee_id" rescue nil
    remove_index "notifications", "notifier_id" rescue nil
    remove_index "notifications", "item_id" rescue nil
    remove_index "notifications", "item_type" rescue nil
    remove_index "people", "organization_id" rescue nil
    remove_index "people", "user_id" rescue nil
    remove_index "people", "contact_list_id" rescue nil
    remove_index "permissions", "user_id" rescue nil
    remove_index "permissions", "item_id" rescue nil
    remove_index "permissions", "item_type" rescue nil
    remove_index "phone_numbers", "person_id" rescue nil
    remove_index "quotas", "organization_id" rescue nil
    remove_index "report_descriptions", "name" rescue nil
    remove_index "reports", "report_description_id" rescue nil
    remove_index "reports", "reportable_id" rescue nil
    remove_index "reports", "reportable_type" rescue nil
    remove_index "reports", "organization_id" rescue nil
    remove_index "reports", "user_id" rescue nil
    remove_index "smart_group_attribute_descriptions", "smart_group_description_id" rescue nil
    remove_index "smart_group_attributes", "smart_group_id" rescue nil
    remove_index "smart_group_attributes", "smart_group_attribute_description_id" rescue nil
    remove_index "smart_group_descriptions", "name" rescue nil
    remove_index "smart_group_descriptions", "item_type" rescue nil
    remove_index "smart_groups", "smart_group_description_id" rescue nil
    remove_index "smart_groups", "user_id" rescue nil
    remove_index "special_dates", "person_id" rescue nil
    remove_index "taggings", "tag_id" rescue nil
    remove_index "taggings", "tagger_id" rescue nil
    remove_index "taggings", "taggable_id" rescue nil
    remove_index "taggings", "taggable_type" rescue nil
    remove_index "tags", "name" rescue nil
    remove_index "tags", "organization_id" rescue nil
    remove_index "user_options", "user_id" rescue nil
    remove_index "user_options", "key" rescue nil
    remove_index "user_requests", "user_id" rescue nil
    remove_index "users", "person_id" rescue nil
    remove_index "users", "username" rescue nil
    remove_index "users", "organization_id" rescue nil
    remove_index "users", "documents_id" rescue nil
    remove_index "websites", "person_id" rescue nil
  end
end
