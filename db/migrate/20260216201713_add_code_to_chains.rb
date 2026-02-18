class AddCodeToChains < ActiveRecord::Migration[8.1]
  def change
    add_column :chains, :code, :string
    add_index :chains, [:company_id, :code], unique: true
  end
end
