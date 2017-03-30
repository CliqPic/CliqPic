class CreateEvents < ActiveRecord::Migration[5.0]
  def change
    create_table :events do |t|
      t.references :user,      null: false, index: true
      t.text       :name,      null: false
      t.timestamp  :start_time
      t.timestamp  :end_time
      t.text       :location
      t.float      :loc_lat
      t.float      :loc_lon
      t.text       :hashtags

      t.timestamps
    end

    add_foreign_key :events, :users
  end
end
