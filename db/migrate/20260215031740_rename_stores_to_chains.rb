class RenameStoresToChains < ActiveRecord::Migration[8.1]
  def change
    rename_table :stores, :chains
    rename_column :chains, :store_type_id, :chain_type_id
  end
end
