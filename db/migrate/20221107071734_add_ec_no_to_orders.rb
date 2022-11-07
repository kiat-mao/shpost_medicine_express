class AddEcNoToOrders < ActiveRecord::Migration[6.0]
  def change
    add_column :orders, :ec_no, :string
    add_column :orders, :order_mode, :string
    add_column :orders, :hospital_no, :string
    add_column :orders, :hospital_name, :string
    add_column :orders, :feight, :boolean
    add_column :orders, :social_no, :string
    add_column :orders, :print_desc, :string
  end
end
