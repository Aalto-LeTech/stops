class CreateUsers < ActiveRecord::Migration
  def self.up
    create_table :users do |t|
      t.string :login, :null => false
      t.string :studentnumber
      t.string :name
      t.database_authenticatable
      t.recoverable
      t.rememberable
      t.trackable
      t.string :locale,                    :default => 'fi', :limit => 5
      t.boolean :admin, :default => false
      t.timestamps
    end
    
    add_index :users, :login, :unique => true
  end

  def self.down
    drop_table :users
    
    create_table :users do |t|
      t.string :login,                :null => false
      t.string :crypted_password,     :limit => 40
      t.string :salt,                 :limit => 40
      t.string :firstname
      t.string :lastname
      t.string :email
      t.boolean :admin
      t.string :locale
      t.integer :thumbs_up, :default => 0
      t.integer :thumbs_down, :default => 0
      t.string :remember_token
      t.datetime :remember_token_expires_at
      t.timestamp :last_login_at
      t.timestamp :previous_login_at
      t.timestamps
    end
  end
end
