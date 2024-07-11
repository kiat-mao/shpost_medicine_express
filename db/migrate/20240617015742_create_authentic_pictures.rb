class CreateAuthenticPictures < ActiveRecord::Migration[6.0]
  def change
    create_table :authentic_pictures do |t|
      t.string   :express_no, index: true
      t.datetime :posting_date

      t.string   :status

      t.datetime :next_time

      t.integer  :sended_times
      
      # t.integer :order_id, index: true

      t.timestamps
    end
  end
end
