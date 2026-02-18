class ChangeChainTypeToBelongToChain < ActiveRecord::Migration[8.1]
  def up
    # Eliminar chain_type_id de chains (ya no necesitan tipo)
    remove_reference :chains, :chain_type, foreign_key: true
    
    # Agregar chain_id a chain_types como nullable primero
    add_reference :chain_types, :chain, null: true, foreign_key: true
    
    # Si hay chain_types existentes, asignarlos a la primera cadena de su compañía
    # o eliminarlos si no hay cadenas
    execute <<-SQL
      UPDATE chain_types
      SET chain_id = (
        SELECT chains.id
        FROM chains
        WHERE chains.company_id = chain_types.company_id
        LIMIT 1
      )
      WHERE chain_id IS NULL
    SQL
    
    # Eliminar chain_types que no pudieron ser asignados (no hay cadenas en su compañía)
    execute "DELETE FROM chain_types WHERE chain_id IS NULL"
    
    # Ahora hacer chain_id NOT NULL
    change_column_null :chain_types, :chain_id, false
    
    # Eliminar company_id de chain_types (ya no es necesario)
    remove_reference :chain_types, :company, foreign_key: true
  end
  
  def down
    # Agregar company_id de vuelta
    add_reference :chain_types, :company, null: true, foreign_key: true
    
    # Asignar company_id desde chain
    execute <<-SQL
      UPDATE chain_types
      SET company_id = (
        SELECT chains.company_id
        FROM chains
        WHERE chains.id = chain_types.chain_id
      )
    SQL
    
    change_column_null :chain_types, :company_id, false
    
    # Eliminar chain_id
    remove_reference :chain_types, :chain, foreign_key: true
    
    # Agregar chain_type_id de vuelta a chains
    add_reference :chains, :chain_type, null: true, foreign_key: true
  end
end
