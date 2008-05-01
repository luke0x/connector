class AddLastAwayRepliedMessageIdToUsers < ActiveRecord::Migration
  def self.up
    add_column :users, :last_away_replied_message_id, :integer, :null => false, :default => 0
  end

  def self.down
    remove_column :users, :last_away_replied_message_id
  end
end
