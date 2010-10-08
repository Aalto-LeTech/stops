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
  end
end
