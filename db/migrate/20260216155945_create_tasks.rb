class CreateTasks < ActiveRecord::Migration[8.1]
  def change
    create_table :tasks do |t|
      t.string :code, null: false
      t.string :name, null: false
      t.text :description
      t.string :task_type, null: false
      t.string :icon_url
      t.text :instructions_template
      t.json :config, default: {}
      t.boolean :active, default: true, null: false
      
      t.timestamps
    end
    
    add_index :tasks, :code, unique: true
    add_index :tasks, :task_type
    add_index :tasks, :active
  end
end
