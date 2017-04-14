class CreateInvitations < ActiveRecord::Migration[5.0]
  def change
    create_table :invitations do |t|
      t.belongs_to :event, foreign_key: true
      t.belongs_to :user, foreign_key: true
      t.text :email, index: true

      t.timestamps
    end
  end
end
