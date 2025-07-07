class AddPrintersToUsers < ActiveRecord::Migration[6.0]
  def change
  	add_column :users, :ems_printer, :string
  	add_column :users, :kdbg_printer, :string
  end
end
