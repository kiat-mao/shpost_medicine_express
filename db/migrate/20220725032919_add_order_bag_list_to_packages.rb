class AddOrderBagListToPackages < ActiveRecord::Migration[6.0]
  def change
  	add_column :packages, :order_list, :string
  	add_column :packages, :bag_list, :string
  end
end
