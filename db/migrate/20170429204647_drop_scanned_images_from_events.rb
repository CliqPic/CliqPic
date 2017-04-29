class DropScannedImagesFromEvents < ActiveRecord::Migration[5.0]
  def change
    remove_column :events, :scanned_images, :integer, default: 0
  end
end
