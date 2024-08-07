class AddProductTypeToOrders < ActiveRecord::Migration[6.0]
  def change
    add_column :orders, :product_type, :string, default: '1'
  end
end
