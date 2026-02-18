class CreateVisitTaskResponses < ActiveRecord::Migration[8.1]
  def change
    create_table :visit_task_responses do |t|
      t.references :visit, null: false, foreign_key: true
      t.references :work_plan_task, null: false, foreign_key: true
      t.json :response_data, default: {}

      t.timestamps
    end
    
    add_index :visit_task_responses, [:visit_id, :work_plan_task_id], unique: true, name: 'index_visit_task_responses_unique'
  end
end
