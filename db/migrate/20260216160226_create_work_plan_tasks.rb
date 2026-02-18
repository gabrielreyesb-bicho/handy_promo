class CreateWorkPlanTasks < ActiveRecord::Migration[8.1]
  def change
    create_table :work_plan_tasks do |t|
      t.references :work_plan, null: false, foreign_key: true
      t.references :task, null: false, foreign_key: true
      t.integer :position, null: false, default: 0
      t.text :instructions
      t.json :data, default: {}
      
      t.timestamps
    end
    
    add_index :work_plan_tasks, [:work_plan_id, :position]
    # El índice en task_id se crea automáticamente con la foreign_key
  end
end
