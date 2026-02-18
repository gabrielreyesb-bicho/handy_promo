class CreateProducts < ActiveRecord::Migration[8.1]
  def change
    unless table_exists?(:products)
      create_table :products do |t|
        t.string :code
        t.string :description
        t.string :barcode
        t.text :comments
        t.references :company, null: false, foreign_key: true
        t.references :unit_of_measure, null: false, foreign_key: true
        t.references :family, null: false, foreign_key: true
        t.boolean :active, default: true

        t.timestamps
      end
      
      add_index :products, [:company_id, :code], unique: true unless index_exists?(:products, [:company_id, :code])
      add_index :products, :barcode unless index_exists?(:products, :barcode)
    end
  end
end
