class GetEventsReadyForAlarms < ActiveRecord::Migration
  def self.up
    add_column :events, :next_fire, :datetime
    add_column :events, :fired, :boolean
  end

  def self.down
    remove_column :events, :next_fire
    remove_column :events, :fired
  end
end
