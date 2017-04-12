class AddImageProcessCounterToEvents < ActiveRecord::Migration[5.0]
  def change
    add_column :events, :image_process_counter, :int, default: 0

    reversible do |dir|
      dir.up do
        execute <<-SQL
          ALTER TABLE events
            ADD CONSTRAINT image_process_counter_is_positive
            CHECK (image_process_counter >= 0)
        SQL
      end

      dir.down do
        execute <<-SQL
          ALTER TABLE events
            DROP CONSTRAINT image_process_counter_is_positive
        SQL
      end
    end
  end
end
