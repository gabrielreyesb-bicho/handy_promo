class CreateRoutes < ActiveRecord::Migration[8.1]
  def change
    create_table :routes do |t|
      t.string :name, null: false
      t.references :company, null: false, foreign_key: true
      t.boolean :active, default: true, null: false
      t.text :comments

      t.timestamps
    end
    
    add_index :routes, :active
    add_index :routes, [:name, :company_id], unique: true
  end
end
