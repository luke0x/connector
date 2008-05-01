class CreatePersonGroupMemberships < ActiveRecord::Migration
  def self.up
    create_table :person_group_memberships do |t|
      t.column :person_id, :integer
      t.column :person_group_id, :integer
      t.column :created_at, :datetime
      t.column :updated_at, :datetime
    end
  end

  def self.down
    drop_table :person_group_memberships
  end
end
