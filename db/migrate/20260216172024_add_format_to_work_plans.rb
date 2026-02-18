class AddFormatToWorkPlans < ActiveRecord::Migration[8.1]
  def change
    add_reference :work_plans, :format, null: true, foreign_key: true
  end
end
