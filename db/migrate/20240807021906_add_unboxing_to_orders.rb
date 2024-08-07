class AddUnboxingToOrders < ActiveRecord::Migration[6.0]
  def change
    add_column :orders, :unboxing, :boolean, default: true
  end
end
