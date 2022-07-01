class CreateUnits < ActiveRecord::Migration[6.0]
  def change
    create_table :units do |t|
			t.string   :name
	    t.string   :desc
	    t.string   :no
			t.string   :short_name
			t.integer  :level
			t.integer  :parent_id
			t.string   :unit_type
	    t.timestamps
    end
  add_index :units, :name, :unique => true
  end
end
