class CreateOrders < ActiveRecord::Migration[6.0]
  def change
    create_table :orders do |t|
      t.string   :order_no, index: true
      t.string   :prescription_no
      t.date   :prescription_date
      t.string   :site_no
      t.string   :site_id
      t.string   :site_name
      t.string   :sender_province
      t.string   :sender_city
      t.string   :sender_district
      t.string   :sender_addr
      t.string   :sender_name
      t.string   :sender_phone
      t.string   :receiver_province
      t.string   :receiver_city
      t.string   :receiver_district
      t.string   :receiver_addr
      t.string   :receiver_name
      t.string   :receiver_phone
      t.string   :customer_addr
      t.string   :customer_name
      t.string   :customer_phone
      t.string   :status
      
      t.integer :package_id, index: true

      t.timestamps
    end
  end
end
