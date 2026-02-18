class ChangeStoreToBelongToRoute < ActiveRecord::Migration[8.1]
  def up
    # Agregar route_id a stores
    add_reference :stores, :route, null: true, foreign_key: true
    
    # Migrar datos de route_stores a stores
    # Si una tienda está en múltiples rutas, tomar la primera
    execute <<-SQL
      UPDATE stores
      SET route_id = (
        SELECT route_id
        FROM route_stores
        WHERE route_stores.store_id = stores.id
        LIMIT 1
      )
      WHERE EXISTS (
        SELECT 1
        FROM route_stores
        WHERE route_stores.store_id = stores.id
      )
    SQL
    
    # Eliminar la tabla route_stores
    drop_table :route_stores
    # El índice de route_id ya se crea automáticamente con add_reference
  end
  
  def down
    # Recrear tabla route_stores
    create_table :route_stores do |t|
      t.references :route, null: false, foreign_key: true
      t.references :store, null: false, foreign_key: true
      t.timestamps
    end
    
    add_index :route_stores, [:route_id, :store_id], unique: true
    
    # Migrar datos de stores.route_id a route_stores
    execute <<-SQL
      INSERT INTO route_stores (route_id, store_id, created_at, updated_at)
      SELECT route_id, id, created_at, updated_at
      FROM stores
      WHERE route_id IS NOT NULL
    SQL
    
    # Eliminar route_id de stores
    remove_reference :stores, :route, foreign_key: true
  end
end
