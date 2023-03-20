class AddOriginalReceiverAddrToOrders < ActiveRecord::Migration[6.0]
  def change
    add_column :orders, :original_receiver_addr, :string
  end
end
