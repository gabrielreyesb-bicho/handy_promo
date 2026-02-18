class AddIndexToProductsCode < ActiveRecord::Migration[8.1]
  def change
    unless index_exists?(:products, [:company_id, :code])
      add_index :products, [:company_id, :code], unique: true
    end
  end
end
