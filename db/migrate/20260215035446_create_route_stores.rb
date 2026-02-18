class CreateRouteStores < ActiveRecord::Migration[8.1]
  def change
    create_table :route_stores do |t|
      t.references :route, null: false, foreign_key: true
      t.references :store, null: false, foreign_key: true

      t.timestamps
    end
    
    add_index :route_stores, [:route_id, :store_id], unique: true
  end
end
