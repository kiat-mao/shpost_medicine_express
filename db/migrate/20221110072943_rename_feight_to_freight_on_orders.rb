class RenameFeightToFreightOnOrders < ActiveRecord::Migration[6.0]
  def change
    rename_column :Orders, :feight, :freight
  end
  def change
    rename_column :Orders, :freight, :feight
  end
end
