class CreateUserFollowersTable < ActiveRecord::Migration[5.0]
  def change
    create_table :users_followers do |t|
      t.integer :user_id,     null: false
      t.integer :follower_id, null: false
    end

    add_foreign_key :users_followers, :users
    add_foreign_key :users_followers, :users, column: :follower_id

    add_index :users_followers, [:user_id, :follower_id], unique: true
  end
end
