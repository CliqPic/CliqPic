class CreateImages < ActiveRecord::Migration[5.0]
  def change
    create_table :images do |t|
      t.integer :instagram_id

      t.text :instagram_link

      t.text :thumbnail_url
      t.text :low_res_url
      t.text :high_res_url

      t.text :hashtags

      t.timestamp :created_on_instagram_at
      
      t.belongs_to :user, foreign_key: true
      t.belongs_to :event, foreign_key: true
      t.belongs_to :album, foreign_key: true

      t.timestamps
    end

    change_table :events do |t|
      t.boolean :fetching_images, default: false
    end
  end
end
