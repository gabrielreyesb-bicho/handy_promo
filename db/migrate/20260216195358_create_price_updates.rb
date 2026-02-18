class CreatePriceUpdates < ActiveRecord::Migration[8.1]
  def change
    create_table :price_updates do |t|
      t.references :product_presentation, null: false, foreign_key: true
      t.references :visit, null: true, foreign_key: true
      t.references :store, null: true, foreign_key: true
      t.references :company, null: false, foreign_key: true
      t.decimal :new_price, precision: 10, scale: 2, null: false
      t.integer :status, default: 0, null: false
      t.datetime :applied_at
      t.text :notes

      t.timestamps
    end
    
    add_index :price_updates, [:visit_id, :status]
    add_index :price_updates, [:store_id, :status]
    add_index :price_updates, [:company_id, :status]
  end
end
