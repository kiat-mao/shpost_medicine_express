class AddInterfaceStatusToOrders < ActiveRecord::Migration[6.0]
  def change
    add_column :orders, :interface_status, :string
  end
end
