class AddValuationAmountToOrders < ActiveRecord::Migration[6.0]
  def change
    add_column :orders, :valuation_amount, :number, default: 0
  end
end
