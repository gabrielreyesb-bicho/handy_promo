class CreateVisits < ActiveRecord::Migration[8.1]
  def change
    create_table :visits do |t|
      t.references :user, null: false, foreign_key: true
      t.references :store, null: false, foreign_key: true
      t.date :scheduled_date, null: false
      t.integer :status, default: 0, null: false

      t.timestamps
    end
    
    add_index :visits, :scheduled_date
    add_index :visits, :status
    add_index :visits, [:user_id, :scheduled_date]
    add_index :visits, [:store_id, :scheduled_date]
  end
end
