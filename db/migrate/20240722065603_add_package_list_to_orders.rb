class AddPackageListToOrders < ActiveRecord::Migration[6.0]
  def change
  	add_column :orders, :package_list, :string, limit: 2000
  end
end
