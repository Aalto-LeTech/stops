class CreateInvitations < ActiveRecord::Migration
  def up
    create_table "invitations" do |t|
      t.string  "token", :null => false
      t.string  "type"
      t.string  "email"
      t.integer "target_id"
      t.timestamp "created_at"
      t.date      "expires_at"
    end
    add_index "invitations", ["token"], :name => "index_invitations_on_token"
    
    create_table :roles do |t|
      t.references :user, :null => false
      t.references :target
      t.string :type
      t.string :role
    end
  end

  def down
    drop_table :invitations
    drop_table :roles
    
    create_table :curriculum_roles, :id => false do |t|
      t.references :curriculum, :null => false
      t.references :user, :null => false
      t.string :role
    end
  end
end
