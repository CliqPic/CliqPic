class ConvertInstagramIdOnImagesToText < ActiveRecord::Migration[5.0]
  def change
    change_column :images, :instagram_id, :text
  end
end
