class ChangeColumnPackage < ActiveRecord::Migration[6.0]
  def up
    change_column :packages, :packed_at, :datetime
  end

  def down
    change_column :packages, :packed_at, :datetime
  end
end


