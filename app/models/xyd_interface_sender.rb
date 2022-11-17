class XydInterfaceSender < ActiveRecord::Base

	def self.address_parsing_schedule
		orders = Order.where(address_status: :address_waiting)
		orders.each_with_index do |order, i|
			self.address_parsing_interface_sender_initialize order
		end
	end

	def self.order_create_interface_sender_initialize(package)
		xydConfig = Rails.application.config_for(:xyd)
		body = self.order_create_request_body_generate(package, xydConfig)
		args = Hash.new
		callback_params = Hash.new
		callback_params["package_id"] = package.id
		args[:callback_params] = callback_params.to_json
		args[:url] = xydConfig[:order_create_url]
		args[:parent_id] = package.id
		args[:unit_id] = package.unit_id
		InterfaceSender.interface_sender_initialize("xyd_order_create", body, args)
	end

	def self.order_create_request_body_generate(package, xydConfig)
		now_time = Time.new

		params = {}
		head = {}
		head["system_name"] = xydConfig[:oc_system_name]
		head["req_time"] = now_time.strftime("%Y%m%d%H%M%S%L")
		head["req_trans_no"] = xydConfig[:oc_system_name] + head["req_time"]
		signature = Digest::MD5.hexdigest("system_name" + head["system_name"] + "req_time" + head["req_time"] + "req_trans_no" + head["req_trans_no"] + xydConfig[:oc_pwd])
		head["signature"] = signature
		params["head"] = head
		body = {}
		body["ecCompanyId"] = xydConfig[:ecCompanyId]
		body["parentId"] = xydConfig[:parentId]
		order = {}
		order["created_time"] = now_time.strftime("%Y-%m-%d %H:%M:%S")
		order["logistics_provider"] = xydConfig[:logistics_provider]
		order["ecommerce_no"] = xydConfig[:ecommerce_no]
		order["ecommerce_user_id"] = now_time.strftime("%Y%m%d%H%M%S%L")
		order["inner_channel"] = xydConfig[:inner_channel]
		order["logistics_order_no"] = "package" + package.package_no

		o = package.orders.first
		# 20221115 区分国药上药
		if xydConfig[:sy_unit_id] == package.unit_id
			if !xydConfig[:sender_no].nil?
				order["sender_no"] = xydConfig[:sy_sender_no]
				order["sender_type"] = '1'
			end
			order["base_product_no"] = xydConfig[:base_product_no_1]
		elsif xydConfig[:gy_unit_id] == package.unit_id
			if !xydConfig[:sender_no].nil?
				order["sender_no"] = xydConfig[:gy_sender_no]
				order["sender_type"] = '1'
			end
			if !o.nil? && o.freight == true
				order["base_product_no"] = xydConfig[:base_product_no_3]
				order["payment_mode"] = xydConfig[:payment_mode_2]
			else
				order["base_product_no"] = xydConfig[:base_product_no_1]
			end
		else
			return "非上药,国药机构!"
		end
		sender = {}
		receiver = {}
		sender["name"] = o.sender_name
		sender["mobile"] = o.sender_phone
		sender["prov"] = o.sender_province
		sender["city"] = o.sender_city
		sender["county"] = o.sender_district
		sender["address"] = o.sender_addr
		receiver["name"] = o.receiver_name
		receiver["mobile"] = o.receiver_phone
		receiver["prov"] = o.receiver_province
		receiver["city"] = o.receiver_city
		receiver["county"] = o.receiver_district
		receiver["address"] = o.receiver_addr
		order["sender"] = sender
		order["receiver"] = receiver
		body["order"] = order
		params["body"] = body

		params.to_json
	end

	def self.get_response_message interfaceSender
		puts 'get_response_message!!'
		if interfaceSender == nil
			return '空的InterfaceSender对象'
		end
		# 优先显示last_response信息,其次是error_msg信息
		last_response_string = interfaceSender.last_response
		if last_response_string != nil
			last_response = JSON.parse last_response_string
			head = last_response["head"]
			if head == nil
				return '不是新一代InterfaceSender对象'
			end
			error_code = head["error_code"]
			error_msg = head["error_msg"]
			if error_code == '0'
				return '成功'
			else
				return error_msg
			end
		else
			error_message = interfaceSender.error_msg
			if (error_message == nil)
				return '未发送'
			else
				return error_message.split("\n")[0]
			end
		end
	end

	def self.order_create_callback_method(response, callback_params)
		puts 'order_create_callback_method!!'
		package_id = nil
		express_no = nil
		route_code = nil
		if callback_params.nil?
			puts 'callback_params:'
		else
			puts 'callback_params:' + callback_params.to_s
			package_id = callback_params["package_id"]
		end
		if response.nil?
			puts 'response:'
			puts '运单号:'
			puts '分拣码:'
			return false
		else
			puts 'response:' + response
			resJSON = JSON.parse response
			resHead = resJSON["head"]
			error_code = resHead["error_code"]
			if (error_code=='0')
				resBody = resJSON["body"]
				express_no = resBody["wayBillNo"]
				route_code = resBody["routeCode"]
				if (!package_id.nil? && package_id.is_a?(Numeric))
					Package.find(package_id).update(express_no: express_no, route_code: route_code)
					puts '运单号:' + express_no.to_s
					puts '分拣码:' + route_code.to_s
					return true
				end
			end
			return false
		end
	end

	def self.address_parsing_interface_sender_initialize(order)
		xydConfig = Rails.application.config_for(:xyd)
		body = self.address_parsing_request_body_generate(order, xydConfig)
		args = Hash.new
		callback_params = Hash.new
		callback_params["order_id"] = order.id
		args[:callback_params] = callback_params.to_json
		args[:url] = xydConfig[:address_parsing_url]
		args[:parent_id] = order.id
		args[:unit_id] = order.unit_id
		InterfaceSender.interface_sender_initialize("xyd_address_parsing", body, args)
	end

	def self.address_parsing_request_body_generate(order, xydConfig)
		now_time = Time.new

		params = {}
		head = {}
		head["system_name"] = xydConfig[:ap_system_name]
		head["req_time"] = now_time.strftime("%Y%m%d%H%M%S%L")
		head["req_trans_no"] = xydConfig[:ap_system_name] + head["req_time"]
		signature = Digest::MD5.hexdigest("system_name" + head["system_name"] + "req_time" + head["req_time"] + "req_trans_no" + head["req_trans_no"] + xydConfig[:ap_pwd])
		head["signature"] = signature
		params["head"] = head
		body = {}
		body["salt"] = xydConfig[:ap_salt]
		addresses = []
		address = {}
		address["address"] = order.receiver_addr
		addresses << address
		body["addresses"] = addresses
		params["body"] = body

		params.to_json
	end

	def self.address_parsing_callback_method(response, callback_params)
		puts 'address_parsing_callback_method!!'
		order_id = nil
		prov_name = nil
		city_name = nil
		county_name = nil
		if callback_params.nil?
			puts 'callback_params:'
		else
			puts 'callback_params:' + callback_params.to_s
			order_id = callback_params["order_id"]
		end
		if response.nil?
			puts 'response:'
			return false
		else
			puts 'response:' + response
			resJSON = JSON.parse response
			resHead = resJSON["head"]
			error_code = resHead["error_code"]
			if (error_code=='0')
				resBody = resJSON["body"]
				results = resBody["results"]
				address = results[0]
				res_code = address["resCode"]
				if res_code == '0000'
					prov_name = address["provName"]
					city_name = address["cityName"]
					county_name = address["countyName"]
					puts '省:' + prov_name.to_s
					puts '市:' + city_name.to_s
					puts '区:' + county_name.to_s
					if (!order_id.nil? && order_id.is_a?(Numeric) && !prov_name.nil? && !city_name.nil? && !county_name.nil? && !prov_name.empty? && !city_name.empty? && !county_name.empty?)
						Order.find(order_id).update(receiver_province: prov_name, receiver_city: city_name, receiver_district: county_name, address_status: :address_success)
						return true
					end
				else
					if (!order_id.nil? && order_id.is_a?(Numeric))
						Order.find(order_id).update(address_status: :address_failed)
						return true
					end
				end
			end
			return false
		end
	end
end