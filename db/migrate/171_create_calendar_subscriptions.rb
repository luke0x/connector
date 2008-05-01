class CreateCalendarSubscriptions < ActiveRecord::Migration
  def self.up
    create_table :calendar_subscriptions do |t|
      t.column :name, :string
      t.column :user_id, :integer
      t.column :organization_id, :integer
      t.column :url, :string
      t.column :username, :string
      t.column :password, :string
      t.column :update_frequency, :string
      t.column :created_at, :datetime
      t.column :updated_at, :datetime
    end
  end

  def self.down
    drop_table :calendar_subscriptions
  end
end
