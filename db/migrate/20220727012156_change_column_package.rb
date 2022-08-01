class ChangeColumnPackage < ActiveRecord::Migration[6.0]
  def change
    change_column :packages, :packed_at, :datetime
  end
end
