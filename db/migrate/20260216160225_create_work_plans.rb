class CreateWorkPlans < ActiveRecord::Migration[8.1]
  def change
    create_table :work_plans do |t|
      t.string :code, null: false
      t.string :name, null: false
      t.text :description
      t.references :company, null: false, foreign_key: true
      t.boolean :active, default: true, null: false
      
      t.timestamps
    end
    
    add_index :work_plans, [:company_id, :code], unique: true
    add_index :work_plans, :active
  end
end
