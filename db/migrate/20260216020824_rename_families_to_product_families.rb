class RenameFamiliesToProductFamilies < ActiveRecord::Migration[8.1]
  def change
    # Renombrar la tabla families a product_families
    rename_table :families, :product_families
    
    # Renombrar la foreign key en products de family_id a product_family_id
    rename_column :products, :family_id, :product_family_id
    
    # Renombrar el índice si existe
    if index_exists?(:product_families, [:company_id, :name])
      rename_index :product_families, 'index_families_on_company_id_and_name', 'index_product_families_on_company_id_and_name'
    end
    
    # Renombrar el índice en products si existe
    if index_exists?(:products, :family_id)
      rename_index :products, 'index_products_on_family_id', 'index_products_on_product_family_id'
    end
  end
end
