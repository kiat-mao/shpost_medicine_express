class AddWeightToOrders < ActiveRecord::Migration[6.0]
  def change
    add_column :orders, :weight, :double
    add_column :orders, :volume, :double
    add_column :orders, :price, :double
  end
end
