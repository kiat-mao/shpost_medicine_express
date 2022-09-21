class AddPrinterToUsers < ActiveRecord::Migration[6.0]
  def change
  	add_column :users, :hot_printer, :string
  	add_column :users, :normal_printer, :string
  end
end
