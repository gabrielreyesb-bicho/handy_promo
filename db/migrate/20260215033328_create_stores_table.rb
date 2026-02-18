class CreateStoresTable < ActiveRecord::Migration[8.1]
  def change
    create_table :stores do |t|
      t.string :name, null: false
      t.string :address
      t.decimal :latitude, precision: 10, scale: 6
      t.decimal :longitude, precision: 10, scale: 6
      t.string :manager_name
      t.string :manager_phone
      t.text :comments
      t.references :chain, null: false, foreign_key: true
      t.references :chain_type, null: false, foreign_key: true
      t.references :company, null: false, foreign_key: true
      t.boolean :active, default: true, null: false

      t.timestamps
    end
    
    add_index :stores, :active
    add_index :stores, [:name, :company_id], unique: true
  end
end
