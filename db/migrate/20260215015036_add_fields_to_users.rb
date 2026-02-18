class AddFieldsToUsers < ActiveRecord::Migration[8.1]
  def up
    # Primero agregar los campos permitiendo null
    add_reference :users, :company, null: true, foreign_key: true
    add_column :users, :name, :string, null: true
    add_column :users, :role, :integer, default: 0
    add_column :users, :active, :boolean, default: true
    
    # Si hay usuarios existentes, crear una compañía por defecto
    if connection.table_exists?('users') && connection.select_value("SELECT COUNT(*) FROM users").to_i > 0
      # Crear compañía por defecto
      default_company_id = connection.insert("INSERT INTO companies (name, active, created_at, updated_at) VALUES ('Compañía por Defecto', 1, datetime('now'), datetime('now'))")
      
      # Actualizar usuarios existentes
      connection.execute("UPDATE users SET company_id = #{default_company_id}, role = 0, active = 1 WHERE company_id IS NULL")
      connection.execute("UPDATE users SET name = 'Usuario' WHERE name IS NULL")
    end
    
    # Ahora hacer los campos NOT NULL
    change_column_null :users, :company_id, false
    change_column_null :users, :name, false
    change_column_null :users, :role, false
    change_column_null :users, :active, false
    
    # El índice de company_id ya se crea automáticamente con add_reference
    add_index :users, :active unless index_exists?(:users, :active)
  end
  
  def down
    remove_index :users, :active
    remove_index :users, :company_id
    remove_column :users, :active
    remove_column :users, :role
    remove_column :users, :name
    remove_reference :users, :company, foreign_key: true
  end
end
