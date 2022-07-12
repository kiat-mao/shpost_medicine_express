class CreateBags < ActiveRecord::Migration[6.0]
  def change
    create_table :bags do |t|
      t.string   :bag_no, index: true
      t.integer :order_id, index: true

      t.timestamps
    end
  end
end
