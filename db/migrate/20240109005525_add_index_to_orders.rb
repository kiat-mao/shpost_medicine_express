class AddIndexToOrders < ActiveRecord::Migration[6.0]
  def change
  	add_index :orders, :prescription_no
  	add_index :orders, :social_no
  	add_index :orders, :receiver_phone
  	add_index :orders, :site_no
  	add_index :orders, :order_mode
  	add_index :orders, :status
  	add_index :orders, :address_status
  	add_index :orders, :bag_list 	
  end
end
