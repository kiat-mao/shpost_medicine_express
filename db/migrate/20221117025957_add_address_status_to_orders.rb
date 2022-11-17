class AddAddressStatusToOrders < ActiveRecord::Migration[6.0]
  def change
    add_column :orders, :address_status, :string
  end
end
