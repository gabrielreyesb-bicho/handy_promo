class CreateStoreTypes < ActiveRecord::Migration[8.1]
  def change
    create_table :store_types do |t|
      t.string :name, null: false
      t.references :company, null: false, foreign_key: true
      t.boolean :active, default: true, null: false

      t.timestamps
    end
    
    add_index :store_types, :active
  end
end
