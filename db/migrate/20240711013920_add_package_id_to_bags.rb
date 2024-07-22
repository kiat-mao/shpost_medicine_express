class AddPackageIdToBags < ActiveRecord::Migration[6.0]
  def change
    add_column :bags, :belong_package_id, :integer
  end
end
