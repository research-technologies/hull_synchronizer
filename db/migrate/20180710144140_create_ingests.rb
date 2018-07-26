class CreateIngests < ActiveRecord::Migration[5.1]
  def change
    create_table :ingests do |t|

      t.timestamps
    end
  end
end
