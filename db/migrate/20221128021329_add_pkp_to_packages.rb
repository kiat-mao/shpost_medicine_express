class AddPkpToPackages < ActiveRecord::Migration[6.0]
  def change
    add_column :packages, :pkp, :string
  end
end
