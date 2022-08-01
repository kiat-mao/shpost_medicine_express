class Order < ApplicationRecord
	has_many :bags
	belongs_to :package, optional: true

	validates_presence_of :order_no, :message => '订单号不能为空'
 	validates_uniqueness_of :order_no, :message => '订单号已存在'

 	enum status: {waiting: 'waiting', packaged: 'packaged'}
 	STATUS_NAME = { waiting: '未装箱', packaged: '已装箱'}

 	def status_name
 		status.blank? ? "" : Order::STATUS_NAME["#{status}".to_sym]
 	end

 	def bag_list
 		self.bags.map{|b| b.bag_no}.compact.join(",")
 	end
end