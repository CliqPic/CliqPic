class AddScannedIdsToEvent < ActiveRecord::Migration[5.0]
  def change
    create_table :events_scanned_images do |t|
      t.references :event
      t.references :image
    end
  end
end
