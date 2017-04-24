class AddOrderToImages < ActiveRecord::Migration[5.0]
  def change
    add_column :images, :order, :int, default: 1
  end
end
