class FixImageUniqueConstraint < ActiveRecord::Migration[5.0]
  def up
    # Remove old index
    remove_index :images, [:event_id, :album_id, :thumbnail_url]

    # Add two new partial indexes
    add_index :images, [:event_id, :album_id, :thumbnail_url], unique: true, where: 'album_id IS NOT NULL'
    add_index :images, [:event_id, :thumbnail_url],            unique: true, where: 'album_id IS NULL'
  end

  def down
    remove_index :images, [:event_id, :album_id, :thumbnail_url]
    remove_index :images, [:event_id, :thumbnail_url]
    
    add_index :images, [:event_id, :album_id, :thumbnail_url], unique: true
  end
end
