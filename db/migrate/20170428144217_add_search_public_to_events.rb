class AddSearchPublicToEvents < ActiveRecord::Migration[5.0]
  def change
    add_column :events, :search_public, :boolean, default: false
  end
end
