class AddForwardingColumn < ActiveRecord::Migration
  def self.up
    add_column "users", "forward_address", :string, :default => ''
  end

  def self.down
    remove_column "users", "forward_address"
  end
end
