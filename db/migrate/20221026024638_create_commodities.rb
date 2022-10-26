class CreateCommodities < ActiveRecord::Migration[6.0]
  def change
    create_table :commodities do |t|
      t.string :commodity_no
      t.string :commodity_name
      t.string :spec
      t.string :batch
      t.integer :num
      t.string :manufacture
      t.date :produced_at
      t.date :expiration_date

      t.integer :order_id, index: true

      t.timestamps
    end
  end
end
