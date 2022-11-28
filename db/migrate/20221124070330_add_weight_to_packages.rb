class AddWeightToPackages < ActiveRecord::Migration[6.0]
  def change
    add_column :packages, :weight, :number
    add_column :packages, :volume, :number
    add_column :packages, :price, :number
  end
end
