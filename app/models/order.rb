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

 	# def get_bag_list
 	# 	self.bags.map{|b| b.bag_no}.compact.join(",")
 	# end

	def self.order_push(context_hash)
		order = Order.find_or_initialize_by order_no: context_hash['ORDER_NO']

		context_hash.keys.each do |key|
			if order.respond_to? "#{key.downcase}="
				order.send "#{key.downcase}=", context_hash[key]
			end
		end
		
		order.bags.destroy_all

		packages_context = context_hash["PACKAGES"]
		bags = packages_context.each{|x| order.bags.new(bag_no: x)}

		order.bag_list = order.bags.map{|x| x.bag_no}.join(',')

		order.waiting!
	end
end