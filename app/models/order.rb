class Order < ApplicationRecord
	has_many :bags
	belongs_to :package, optional: true

	validates_presence_of :order_no, :message => '订单号不能为空'
 	validates_uniqueness_of :order_no, :message => '订单号已存在'

 	enum status: {waiting: 'waiting', packaged: 'packaged'}
end