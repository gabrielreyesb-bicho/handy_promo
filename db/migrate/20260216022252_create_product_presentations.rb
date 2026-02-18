class CreateProductPresentations < ActiveRecord::Migration[8.1]
  def change
    create_table :product_presentations do |t|
      t.references :product, null: false, foreign_key: true
      t.string :code, null: false
      t.string :barcode
      t.decimal :size, precision: 10, scale: 2
      t.references :unit_of_measure, null: false, foreign_key: true
      t.text :comments
      t.boolean :active, default: true, null: false
      
      t.timestamps
    end
    
    add_index :product_presentations, [:product_id, :code], unique: true
    add_index :product_presentations, :barcode, unique: true
    add_index :product_presentations, :active
  end
end
