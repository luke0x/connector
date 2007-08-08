class AddNotifierStatuses < ActiveRecord::Migration
  def self.up
    add_column :phone_numbers, :notify, :boolean, :default => false
    add_column :email_addresses, :notify, :boolean, :default => false
    add_column :im_addresses, :notify, :boolean, :default => false
  end

  def self.down
    remove_column :phone_numbers, :notify
    remove_column :email_addresses, :notify
    remove_column :im_addresses, :notify
  end
end
