class AddNameToProducts < ActiveRecord::Migration[8.1]
  def up
    add_column :products, :name, :string, null: false, default: ''
    
    # Migrar description a name para productos existentes
    execute <<-SQL
      UPDATE products SET name = COALESCE(description, 'Producto sin nombre')
      WHERE name = ''
    SQL
    
    change_column_default :products, :name, nil
    add_index :products, [:company_id, :name], unique: true
  end
  
  def down
    remove_index :products, [:company_id, :name] if index_exists?(:products, [:company_id, :name])
    remove_column :products, :name, :string
  end
end
