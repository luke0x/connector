class CreateMailAliases < ActiveRecord::Migration
  def self.up
    create_table :mail_aliases do |t|
      t.column :name,            :string
      t.column :organization_id, :integer
      t.column :created_at,      :datetime
      t.column :updated_at,      :datetime
    end
  end

  def self.down
    drop_table :mail_aliases
  end
end
