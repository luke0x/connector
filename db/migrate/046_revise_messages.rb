=begin #(fold)
++
Copyright 2004-2007 Joyent Inc.

Redistribution and/or modification of this code is 
governed by the GPLv2.

Report issues and contribute at http://dev.joyent.com/

$Id$
--
=end #(end)

class ReviseMessages < ActiveRecord::Migration
  def self.up
    drop_table :messages
    
    create_table :messages do |t|  
      t.column :organization_id, :integer
      t.column :user_id,         :integer
      t.column :mailbox_id,      :integer
      t.column :size_in_bytes,   :integer
      t.column :created_at,      :datetime
      t.column :updated_at,      :datetime
    end
  end

  def self.down
    drop_table :messages
    
    create_table :messages do |t|  
      t.column :uid,             :integer
      t.column :message_id,      :string
      t.column :to,              :string
      t.column :cc,              :string
      t.column :bcc,             :string
      t.column :from,            :string
      t.column :reply_to,        :string
      t.column :subject,         :string
      t.column :sent,            :datetime
      t.column :received,        :datetime
      t.column :attachments,     :integer, :default => 0
      t.column :size,            :integer, :default => 0
      t.column :draft,           :boolean, :default => false
      t.column :flagged,         :boolean, :default => false
      t.column :read,            :boolean, :default => false
      t.column :replied_to,      :boolean, :default => false
      t.column :forwarded,       :boolean, :default => false
      t.column :deleted,         :boolean, :default => false
      t.column :mailbox_id,      :integer
      t.column :organization_id, :integer
      t.column :user_id,         :integer
      t.column :created_at,      :datetime
      t.column :updated_at,      :datetime
    end
  end
end
