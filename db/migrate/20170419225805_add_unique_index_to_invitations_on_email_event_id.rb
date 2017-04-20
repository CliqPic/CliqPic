class AddUniqueIndexToInvitationsOnEmailEventId < ActiveRecord::Migration[5.0]
  def change
    add_index :invitations, [:event_id, :email], unique: true, where: 'email IS NOT NULL'
    add_index :invitations, [:event_id, :user_id], unique: true, where: 'user_id IS NOT NULL'
  end
end
