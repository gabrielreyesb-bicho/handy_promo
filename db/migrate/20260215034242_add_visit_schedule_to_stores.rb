class AddVisitScheduleToStores < ActiveRecord::Migration[8.1]
  def change
    add_column :stores, :visit_day, :integer
    add_column :stores, :visit_frequency, :integer, default: 0
  end
end
