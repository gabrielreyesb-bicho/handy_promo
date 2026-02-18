class AddCodeToFormats < ActiveRecord::Migration[8.1]
  def change
    add_column :formats, :code, :string
    add_index :formats, [:chain_id, :code], unique: true
  end
end
