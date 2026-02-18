class CreateUnitOfMeasures < ActiveRecord::Migration[8.1]
  def change
    create_table :unit_of_measures do |t|
      t.string :name
      t.references :company, null: false, foreign_key: true
      t.boolean :active, default: true

      t.timestamps
    end
    
    add_index :unit_of_measures, [:company_id, :name], unique: true
  end
end
