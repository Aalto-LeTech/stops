class CreateComments < ActiveRecord::Migration
  def up
    create_table :comments do |t|
      t.references :user
      t.references :comment
      t.references :commentable, :polymorphic => true, :null => false
      t.text :comment
      
      t.timestamps
    end
  end

  def down
    drop_table :comments
  end
end
