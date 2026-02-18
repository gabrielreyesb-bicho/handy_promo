class RemovePresentationFieldsFromProducts < ActiveRecord::Migration[8.1]
  def change
    # Remover campos que ahora están en product_presentations
    remove_column :products, :code, :string
    remove_column :products, :barcode, :string
    remove_column :products, :size, :decimal
    remove_column :products, :unit_of_measure_id, :integer
    
    # Remover índices relacionados
    remove_index :products, [:company_id, :code] if index_exists?(:products, [:company_id, :code])
    remove_index :products, :barcode if index_exists?(:products, :barcode)
  end
end
