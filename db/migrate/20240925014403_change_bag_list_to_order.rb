class ChangeBagListToOrder < ActiveRecord::Migration[6.0]
  def up
    change_column :orders, :bag_list, :string, limit: 1000
  end
  def down
    change_column :orders, :bag_list, :string, limit: 1000
  end
end
