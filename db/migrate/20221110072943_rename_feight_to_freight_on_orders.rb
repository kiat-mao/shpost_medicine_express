class RenameFeightToFreightOnOrders < ActiveRecord::Migration[6.0]
  def change
    rename_column :orders, :feight, :freight
  end
end
