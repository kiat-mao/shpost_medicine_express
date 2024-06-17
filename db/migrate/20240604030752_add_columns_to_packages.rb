class AddColumnsToPackages < ActiveRecord::Migration[6.0]
  def change
  	add_column :packages, :valuation_sum, :number, default: 0
  	add_column :packages, :sorting_code, :string
  end
end
