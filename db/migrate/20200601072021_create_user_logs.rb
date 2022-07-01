class CreateUserLogs < ActiveRecord::Migration[6.0]
  def change
    create_table :user_logs do |t|
    	t.integer  :user_id,    :null => false, :default => 0
    	t.string   :operation,  :null => false, :default => ""
    	t.string   :object_class
    	t.integer  :object_primary_key
    	t.string   :object_symbol
    	t.string   :desc
    	t.integer  :parent_id
    	t.string   :parent_type
    	t.timestamps
    end
  end
end
