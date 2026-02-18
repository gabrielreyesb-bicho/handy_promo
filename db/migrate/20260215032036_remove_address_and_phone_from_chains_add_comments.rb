class RemoveAddressAndPhoneFromChainsAddComments < ActiveRecord::Migration[8.1]
  def change
    remove_column :chains, :address, :string
    remove_column :chains, :phone, :string
    add_column :chains, :comments, :text
  end
end
