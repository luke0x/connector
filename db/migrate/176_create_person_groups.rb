class CreatePersonGroups < ActiveRecord::Migration
  def self.up
    create_table :person_groups do |t|
      t.column  :user_id, :integer
      t.column  :organization_id, :integer      
      t.column  :name, :string
      t.column  :created_at, :datetime
      t.column  :updated_at, :datetime
    end
  end

  def self.down
    drop_table :person_groups
  end
end
