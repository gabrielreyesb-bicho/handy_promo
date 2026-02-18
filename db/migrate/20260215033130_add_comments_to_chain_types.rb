class AddCommentsToChainTypes < ActiveRecord::Migration[8.1]
  def change
    add_column :chain_types, :comments, :text
  end
end
