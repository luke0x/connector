class AddSmsSupportForPhoneNumbers < ActiveRecord::Migration
  def self.up
    add_column :phone_numbers, :confirmation_number, :string
    add_column :phone_numbers, :confirmed, :boolean, :default => false
    add_column :phone_numbers, :provider, :string
  end

  def self.down
    remove_column :phone_numbers, :confirmation_number
    remove_column :phone_numbers, :confirmed
    remove_column :phone_numbers, :provider
  end
end
