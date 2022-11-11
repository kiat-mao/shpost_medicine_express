class ChangeWeightToNumberOnOrders < ActiveRecord::Migration[6.0]
  def change
    change_column :orders, :weight, :number
    change_column :orders, :volume, :number
    change_column :orders, :price, :number
  end
end
