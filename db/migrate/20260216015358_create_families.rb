class CreateFamilies < ActiveRecord::Migration[8.1]
  def change
    create_table :families do |t|
      t.string :name
      t.references :company, null: false, foreign_key: true
      t.boolean :active, default: true

      t.timestamps
    end
    
    add_index :families, [:company_id, :name], unique: true
  end
end
