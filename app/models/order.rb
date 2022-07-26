class Order < ApplicationRecord
	has_many :bags
	belongs_to :package, optional: true

	validates_presence_of :order_no, :message => '订单号不能为空'
	validates_uniqueness_of :order_no, :message => '订单号已存在'

	enum status: {waiting: 'waiting', packaged: 'packaged'}

	def self.order_push(context_hash)
		order = Order.new

		context_hash.keys.each do |key|
			if order.respond_to? "#{key.downcase}="
				order.send "#{key.downcase}=", context_hash[key]
			end
		end
		

		packages_context = context_hash["PACKAGES"]
		bags = packages_context.each{|x| order.bags <<  Bag.new(bag_no: x)}

		order.waiting!
	end
end