class AddTmpPackageToOrders < ActiveRecord::Migration[6.0]
  def change
  	add_column :orders, :tmp_package, :string
  end
end
