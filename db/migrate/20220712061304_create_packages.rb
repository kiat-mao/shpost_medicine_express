class CreatePackages < ActiveRecord::Migration[6.0]
  def change
    create_table :packages do |t|
      t.string   :package_no, index: true
      t.string   :express_no, index: true
      t.string   :route_code
      t.string   :status

      t.date  :packed_at

      t.integer :user_id, index: true

      t.timestamps
    end
  end
end
