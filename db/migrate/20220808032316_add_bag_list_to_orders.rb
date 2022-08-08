class AddBagListToOrders < ActiveRecord::Migration[6.0]
  def change
  	add_column :orders, :bag_list, :string
  end
end
