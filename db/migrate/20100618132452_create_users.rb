class CreateUsers < ActiveRecord::Migration
  def self.up
    create_table :users do |t|
      t.string :login
      t.string :studentnumber
      t.string :name
      t.string :email, :limit => 320
      t.string :locale,                    :default => 'fi', :limit => 5
      t.boolean :admin, :default => false
      
      t.string :crypted_password, :null => false
      t.string :password_salt, :null => false
      t.string :persistence_token, :null => false
      
      t.integer :login_count, :default => 0, :null => false
      t.datetime :last_request_at
      t.datetime :last_login_at
      t.datetime :current_login_at
      
      t.timestamps
    end
    
    add_index :users, :login, :unique => true
    add_index :users, :studentnumber, :unique => true
    add_index :users, :persistence_token
    add_index :users, :last_request_at
  end

  def self.down
    drop_table :users
  end
end
