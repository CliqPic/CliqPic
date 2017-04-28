class AddPublicToInvitations < ActiveRecord::Migration[5.0]
  def change
    add_column :invitations, :public, :boolean, default: false
  end
end
