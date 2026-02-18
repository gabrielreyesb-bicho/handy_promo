class AddSegmentToStores < ActiveRecord::Migration[8.1]
  def change
    add_reference :stores, :segment, null: true, foreign_key: true
  end
end
