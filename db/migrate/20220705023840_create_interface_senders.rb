class CreateInterfaceSenders < ActiveRecord::Migration[6.0]
  def change
    create_table :interface_senders do |t|
      t.string   :url
      t.string   :host
      t.string   :port
      t.string   :interface_type
      t.string   :http_type
      t.string   :callback_class
      t.string   :callback_method
      t.text     :callback_params
      t.string   :status
      t.integer  :send_times
      t.datetime :next_time
      t.text     :header
      t.text     :body
      t.datetime :last_time
      t.text     :last_response
      t.text     :last_header
      t.string   :interface_code
      t.integer  :max_times
      t.integer  :interval
      t.text     :error_msg
      t.string   :parent_class
      t.integer  :parent_id
      t.integer  :unit_id
      t.integer  :business_id

      t.timestamps
    end

  end
end
