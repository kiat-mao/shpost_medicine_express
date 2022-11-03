class ChangeBagListToOrders < ActiveRecord::Migration[6.0]
  def up
    change_column :packages, :bag_list, :string, limit: 2000
  end
  def down
    change_column :packages, :bag_list, :string, limit: 2000
  end
end
