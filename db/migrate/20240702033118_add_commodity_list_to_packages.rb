class AddCommodityListToPackages < ActiveRecord::Migration[6.0]
  def change
  	add_column :packages, :commodity_list, :string, limit: 2000
  end
end
