class RenameChainTypesToFormats < ActiveRecord::Migration[8.1]
  def up
    # Renombrar la tabla chain_types a formats
    rename_table :chain_types, :formats
    
    # Renombrar la columna chain_type_id a format_id en stores
    rename_column :stores, :chain_type_id, :format_id
    
    # Renombrar índices si existen
    if index_exists?(:stores, :chain_type_id)
      rename_index :stores, :index_stores_on_chain_type_id, :index_stores_on_format_id
    end
  end
  
  def down
    # Revertir los cambios
    rename_column :stores, :format_id, :chain_type_id
    
    if index_exists?(:stores, :format_id)
      rename_index :stores, :index_stores_on_format_id, :index_stores_on_chain_type_id
    end
    
    rename_table :formats, :chain_types
  end
end
