class AddDevise < ActiveRecord::Migration
  def self.up
    #drop_table :users
    
    create_table :users do |t|
      t.string :login, :null => false
      t.string :name
      t.database_authenticatable
      t.recoverable
      t.rememberable
      t.trackable
      t.boolean :admin, :default => false
      t.timestamps
    end
  end
  
  def self.down
    drop_table :users
  end
end
