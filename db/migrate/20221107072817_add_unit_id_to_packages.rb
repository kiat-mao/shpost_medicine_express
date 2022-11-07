class AddUnitIdToPackages < ActiveRecord::Migration[6.0]
  def change
    add_column :packages, :unit_id, :string
  end
end
