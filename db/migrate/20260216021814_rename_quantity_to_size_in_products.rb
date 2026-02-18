class RenameQuantityToSizeInProducts < ActiveRecord::Migration[8.1]
  def change
    rename_column :products, :quantity, :size
  end
end
