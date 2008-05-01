class AddCalendarSubscriptionIdToEvents < ActiveRecord::Migration
  def self.up
    add_column :events, :calendar_subscription_id, :integer
  end

  def self.down
    remove_column :events, :calendar_subscription_id
  end
end
