class AddRoles < ActiveRecord::Migration
  def up
    add_column :users, :staff, :boolean, :default => false

    create_table :curriculum_roles, :id => false do |t|
      t.references :curriculum, :null => false
      t.references :user, :null => false
      t.string :role
    end
  end

  def down
    remove_column :users, :staff
    drop_table :curriculum_roles
  end
end
