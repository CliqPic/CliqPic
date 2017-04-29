class DropFetchingImagesAndImageProcessCounterFromEvents < ActiveRecord::Migration[5.0]
  def change
    remove_column :events, :image_process_counter, :integer
    remove_column :events, :fetching_images, :integer
  end
end
