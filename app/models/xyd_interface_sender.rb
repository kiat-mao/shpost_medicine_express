class XydInterfaceSender < ActiveRecord::Base

	def self.order_create_interface_sender_initialize(package)
		body = self.order_create_request_body_generate package
		args = Hash.new
		callback_params = Hash.new
		callback_params["package_id"] = package.id
		args[:callback_params] = callback_params.to_json
		InterfaceSender.interface_sender_initialize("xyd_order_create", body, args)
	end

	def self.order_create_request_body_generate(package)
		now_time = Time.new
		xydConfig = Rails.application.config_for(:xyd)

		params = {}
		head = {}
		head["system_name"] = xydConfig[:system_name]
		head["req_time"] = now_time.strftime("%Y%m%d%H%M%S%L")
		head["req_trans_no"] = xydConfig[:system_name] + head["req_time"]
		signature = Digest::MD5.hexdigest("system_name" + head["system_name"] + "req_time" + head["req_time"] + "req_trans_no" + head["req_trans_no"] + xydConfig[:pwd])
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
		order["base_product_no"] = xydConfig[:base_product_no]
		
		o = package.orders.first
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

	def self.order_create_send_success(response, callback_params)
		puts 'order_create_send_success!!'
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
				end
			end
			puts '运单号:' + express_no
			puts '分拣码:' + route_code
		end
	end
end