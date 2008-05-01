class AddAwayFieldsToUser < ActiveRecord::Migration
  def self.up
    add_column :users, :away_on, :boolean, :default => false
    add_column :users, :away_expires_at, :date
    add_column :users, :away_message, :text
  end

  def self.down
    remove_column :users, :away_on
    remove_column :users, :away_expires_at
    remove_column :users, :away_message
  end
end
