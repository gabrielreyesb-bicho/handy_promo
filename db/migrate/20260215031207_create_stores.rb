class CreateStores < ActiveRecord::Migration[8.1]
  def change
    create_table :stores do |t|
      t.string :name, null: false
      t.string :address
      t.string :phone
      t.references :store_type, null: false, foreign_key: true
      t.references :company, null: false, foreign_key: true
      t.boolean :active, default: true, null: false

      t.timestamps
    end
    
    add_index :stores, :active
  end
end
