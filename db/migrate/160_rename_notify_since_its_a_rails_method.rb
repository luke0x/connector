class RenameNotifySinceItsARailsMethod < ActiveRecord::Migration
  def self.up
    rename_column :phone_numbers, :notify, :use_notifier
    rename_column :email_addresses, :notify, :use_notifier
    rename_column :im_addresses, :notify, :use_notifier
  end

  def self.down
    rename_column :phone_numbers, :use_notifier, :notify
    rename_column :email_addresses, :use_notifier, :notify
    rename_column :im_addresses, :use_notifier, :notify
  end
end
