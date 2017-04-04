class CreateAlbums < ActiveRecord::Migration[5.0]
  def change
    create_table :albums do |t|
      t.text :name, null: false
      t.belongs_to :event, foreign_key: true

      t.timestamps
    end
  end
end
