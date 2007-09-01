class ModifyPrimaryEmailAndPhoneNumber < ActiveRecord::Migration
  def self.up
    rename_column :people, :primary_phone, :primary_phone_cache
    rename_column :people, :primary_email, :primary_email_cache
  end

  def self.down
    rename_column :people, :primary_phone_cache, :primary_phone
    rename_column :people, :primary_email_cache, :primary_email
  end
end
