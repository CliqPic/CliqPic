class ChangeEventUserIdToOwnerId < ActiveRecord::Migration[5.0]
  def change
    rename_column :events, :user_id, :owner_id
  end
end
