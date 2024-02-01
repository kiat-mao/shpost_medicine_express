class AddPayModeToOrders < ActiveRecord::Migration[6.0]
  def change
    add_column :orders, :pay_mode, :string
  end
end
