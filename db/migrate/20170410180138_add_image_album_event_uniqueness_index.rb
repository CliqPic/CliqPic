class AddImageAlbumEventUniquenessIndex < ActiveRecord::Migration[5.0]
  def change
    add_index :images, [:event_id, :album_id, :thumbnail_url], unique: true
  end
end
