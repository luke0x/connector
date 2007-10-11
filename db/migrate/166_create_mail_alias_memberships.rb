class CreateMailAliasMemberships < ActiveRecord::Migration
  def self.up
    create_table :mail_alias_memberships do |t|
      t.column :user_id,       :integer
      t.column :mail_alias_id, :integer
      t.column :created_at,    :datetime
      t.column :updated_at,    :datetime
    end
  end

  def self.down
    drop_table :mail_alias_memberships
  end
end
