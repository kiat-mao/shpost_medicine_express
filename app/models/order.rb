class Order < ApplicationRecord
	has_many :bags, dependent: :destroy
	has_many :commodities, dependent: :destroy
	belongs_to :package, optional: true
	belongs_to :unit, optional: true

	validates_presence_of :order_no, :message => '订单号不能为空'
	validates_uniqueness_of :order_no, :message => '订单号已存在'

	enum status: {waiting: 'waiting', packaged: 'packaged'}
	STATUS_NAME = { waiting: '未装箱', packaged: '已装箱'}

	enum interface_status: {interface_waiting: 'interface_waiting', need_send: 'need_send', to_send: 'to_send', failed: 'failed', done: 'done'}
	INTERFACE_STATUS_NAME = {interface_waiting: '待发送', need_send: '可以发送', to_send: '发送队列中', failed: '发送失败', done: '发送成功'}

	enum address_status: {address_waiting: 'address_waiting', address_success: 'address_success', address_failed: 'address_failed', address_noparse: 'address_noparse', address_parseing: 'address_parseing'}
	ADDRESS_STATUS_NAME = {address_waiting: '待解析', address_success: '解析成功', address_failed: '解析失败', address_noparse: '不解析', address_parseing: '解析中'}

	def status_name
		status.blank? ? "" : Order::STATUS_NAME["#{status}".to_sym]
	end

	def interface_status_name
		interface_status.blank? ? "" : Order::INTERFACE_STATUS_NAME["#{interface_status}".to_sym]
	end

	def address_status_name
		address_status.blank? ? "" : Order::ADDRESS_STATUS_NAME["#{address_status}".to_sym]
	end

	def self.order_push(context_hash, unit = nil)
		order = Order.find_or_initialize_by(order_no: context_hash['ORDER_NO'], unit: unit)

		order.unit = unit 

		context_hash.keys.each do |key|
			next if key.eql? "COMMODITIES"

			if order.respond_to? "#{key.downcase}="
				order.send "#{key.downcase}=", context_hash[key]
			end
		end
		
		order.bags.destroy_all
		order.commodities.destroy_all
		order.waiting!

		packages_context = context_hash["PACKAGES"]
		bags = packages_context.each{|x| order.bags.new(bag_no: x)}

		order.bag_list = order.bags.map{|x| x.bag_no}.join(',')


		commodities_context = context_hash["COMMODITIES"]
		if !commodities_context.blank?
			commodities_context.each do |commodity|
				c = order.commodities.new
				commodity.keys.each do |key|
					if c.respond_to? "#{key.downcase}="
						c.send "#{key.downcase}=", commodity[key]
					end
				end
			end
		end

		order.interface_waiting! 
		# order.waiting!
	end
end