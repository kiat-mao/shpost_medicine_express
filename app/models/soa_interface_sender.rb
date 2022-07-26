class SoaInterfaceSender < ActiveRecord::Base



	def self.order_trace_interface_sender_initialize(package)
		body = self.order_trace_request_body_generate package
		args = Hash.new
		callback_params = Hash.new
		callback_params["package_id"] = package.id
		args[:callback_params] = callback_params.to_json
		InterfaceSender.interface_sender_initialize("soa_order_trace", body, args)
	end

	def self.order_trace_request_body_generate(package)
		now_time = Time.new
		soaConfig = Rails.application.config_for(:soa)

		params = {}
		commonHeader = {}
		commonHeader["ACCOUNT"] = ''
		commonHeader["PASSWORD"] = ''
		commonHeader["CONSUMER"] = soaConfig[:consumer]
		commonHeader["COUNT"] = soaConfig[:count]
		commonHeader["BIZTRANSACTIONID"] = 'order_trace_send_' + now_time.strftime("%Y%m%d%H%M%S%L")
		commonHeader["SRVLEVEL"] = soaConfig[:srvlevel]

		list = {}
		orderIraces = []
		package.orders.each_with_index do |order, i|
			orderIrace = {}
			orderIrace["container"] = package.express_no
			orderIrace["volume"] = '1'
			orderIrace["shpmtNbr"] = package.express_no
			orderIrace["orderNo"] = order.order_no
			orderIrace["pOrder"] = ''
			orderIrace["lpnId"] = '1'
			orderIrace["lpnDetailId"] = '1'
			orderIrace["itemName"] = '1'
			orderIrace["batchNbr"] = '1'
			orderIrace["qty"] = '1'
			orderIrace["procStatCode"] = '1' # 标记（1新增，2修改）
			orderIrace["packedDateTime"] = package.packed_at
			orderIrace["whse"] = 'FR2'
			orderIraces[i] = orderIrace
		end
		
		list["orderIrace"] = orderIraces
		params["commonHeader"] = commonHeader
		params["LIST"] = list

		params.to_json
	end

	def self.order_trace_send_success(response, callback_params)
		puts 'order_trace_send_success!!'
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
			puts 'result:'
			puts 'code:'
			puts 'message:'
		else
			puts 'response:' + response
			resJSON = JSON.parse response
			commonHeader = resJSON["commonHeader"]
			result = commonHeader["RESULT"]
			if (result=='0')
				list = resJSON["LIST"]
				code = list["code"]
				message = resBody["message"]
				if (!package_id.nil? && package_id.is_a?(Numeric))
					Package.find(package_id).update(status: :done)
				end
			end
			puts 'result:' + result.to_s
			puts 'code:' + code
			puts 'message:' + message
		end

	end

end