class AddMoreInstagramDataToImages < ActiveRecord::Migration[5.0]
  def change
    add_column :images, :lat, :float
    add_column :images, :lon, :float
  end
end
