class RenameStoreTypesToChainTypes < ActiveRecord::Migration[8.1]
  def change
    rename_table :store_types, :chain_types
  end
end
