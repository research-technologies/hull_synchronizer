class CreateDataMappers < ActiveRecord::Migration[5.1]
  def change
    create_table :data_mappers do |t|
      t.string :title
      t.string :file_type
      t.integer :rows
      t.integer :rows_processed
      t.string :status
      t.text :message

      t.timestamps
    end
  end
end
