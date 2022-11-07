class AddUnitIdToOrders < ActiveRecord::Migration[6.0]
  def change
    add_column :orders, :unit_id, :string
  end
end
