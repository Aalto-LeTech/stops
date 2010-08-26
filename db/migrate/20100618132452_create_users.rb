class CreateUsers < ActiveRecord::Migration
  def self.up
    create_table :users do |t|
      t.string :login,                     :null => false
      t.string :studentnumber
      t.string :name
      t.string :email,                     :limit => 320
      t.string :crypted_password,          :limit => 40
      t.string :salt,                      :limit => 40
      t.string :remember_token,            :limit => 40
      t.boolean :admin,                    :default => false
      t.string :locale,                    :default => 'fi', :limit => 5
      t.datetime :remember_token_expires_at
      t.timestamps
    end

    add_index :users, :login, :unique => true
  end

  def self.down
    drop_table :users
  end
end
