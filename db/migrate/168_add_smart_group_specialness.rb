class AddSmartGroupSpecialness < ActiveRecord::Migration
  def self.up
    add_column "smart_groups", "special", :boolean, :default => false
  end

  def self.down
    remove_column "smart_groups", "special"
  end
end
