class AddNoModifyToOrders < ActiveRecord::Migration[6.0]
  def change
  	add_column :orders, :no_modify, :boolean, :default => false
  end
end
