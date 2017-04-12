class ChangeUserUniquenessIndex < ActiveRecord::Migration[5.0]
  def up
    remove_index :users, :email
    add_index :users, :uid, unique: true
  end
  
  def down
    remove_index :users, :uid
    add_index :users, :email, unique: true
  end
end
