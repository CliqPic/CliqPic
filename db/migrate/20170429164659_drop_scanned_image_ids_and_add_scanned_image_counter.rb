class DropScannedImageIdsAndAddScannedImageCounter < ActiveRecord::Migration[5.0]
  def change
    drop_table :events_scanned_images

    add_column :events, :scanned_images, :integer, default: 0
  end
end
