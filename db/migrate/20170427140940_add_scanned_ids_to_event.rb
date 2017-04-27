class AddScannedIdsToEvent < ActiveRecord::Migration[5.0]
  def change
    add_column :events, :scanned_ids, :string, array: true, default: []
  end
end
