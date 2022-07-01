class CreateUsers < ActiveRecord::Migration[6.0]
  def change
    create_table :users do |t|
      t.string :email,              :null => false, :default => ""
      t.string :encrypted_password, :null => false, :default => ""

      ## Recoverable
      t.string   :reset_password_token
      t.datetime :reset_password_sent_at

      ## Rememberable
      t.datetime :remember_created_at

      ## Trackable
      t.integer  :sign_in_count, :default => 0, :null => false
      t.datetime :current_sign_in_at
      t.datetime :last_sign_in_at
      t.string   :current_sign_in_ip
      t.string   :last_sign_in_ip
      t.string   :username,      :null => false, :default => ""
      t.string   :role,    :null => false, :default => ""
      t.string   :name
      t.string   :status
      t.integer  :unit_id
      t.datetime :locked_at
      t.integer  :failed_attempts, :default => 0
      t.timestamps
    end

    add_index :users, :username, :unique => true
  end
end
