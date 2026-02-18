class MigrateProductsToPresentations < ActiveRecord::Migration[8.1]
  def up
    # Migrar datos existentes de products a product_presentations
    # Cada producto existente se convierte en un producto con 1 presentación
    execute <<-SQL
      INSERT INTO product_presentations (
        product_id,
        code,
        barcode,
        size,
        unit_of_measure_id,
        comments,
        active,
        created_at,
        updated_at
      )
      SELECT 
        id as product_id,
        COALESCE(code, 'TEMP-' || id) as code,
        barcode,
        size,
        unit_of_measure_id,
        comments,
        active,
        created_at,
        updated_at
      FROM products
    SQL
  end
  
  def down
    # Revertir: copiar datos de presentaciones de vuelta a products
    execute <<-SQL
      UPDATE products p
      SET 
        code = pp.code,
        barcode = pp.barcode,
        size = pp.size,
        unit_of_measure_id = pp.unit_of_measure_id,
        comments = pp.comments,
        active = pp.active
      FROM product_presentations pp
      WHERE pp.product_id = p.id
      AND pp.id = (
        SELECT id FROM product_presentations 
        WHERE product_id = p.id 
        ORDER BY created_at ASC 
        LIMIT 1
      )
    SQL
  end
end
