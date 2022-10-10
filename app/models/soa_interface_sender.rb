class SoaInterfaceSender < ActiveRecord::Base



	def self.order_trace_interface_sender_initialize(package)
		soaConfig = Rails.application.config_for(:soa)
		body = self.order_trace_request_body_generate(package, soaConfig)
		args = Hash.new
		callback_params = Hash.new
		callback_params["package_id"] = package.id
		args[:callback_params] = callback_params.to_json
		args[:url] = soaConfig[:order_trace_url]
		InterfaceSender.interface_sender_initialize("soa_order_trace", body, args)
		package.update status: "to_send"
	end

	def self.order_trace_request_body_generate(package, soaConfig)
		now_time = Time.new

		params = {}
		commonHeader = {}
		commonHeader["ACCOUNT"] = ''
		commonHeader["PASSWORD"] = ''
		commonHeader["CONSUMER"] = soaConfig[:consumer]
		commonHeader["COUNT"] = soaConfig[:count]
		commonHeader["BIZTRANSACTIONID"] = 'SendTMP_ORDER_TRACE_PS_' + now_time.strftime("%Y%m%d%H%M%S%L")
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
			if package.packed_at.nil?
				orderIrace["packedDateTime"] = nil
			else
				orderIrace["packedDateTime"] = package.packed_at.strftime("%Y-%m-%d %H:%M:%S")
			end
			orderIrace["whse"] = 'FR2'
			orderIrace["udf01"] = 'ZGYZ'
			orderIraces[i] = orderIrace
		end
		
		list["orderIrace"] = orderIraces
		params["commonHeader"] = commonHeader
		params["LIST"] = list

		params.to_json
	end

	def self.order_trace_callback_method(response, callback_params)
		puts 'order_trace_callback_method!!'
		package_id = nil
		express_no = nil
		route_code = nil
		if callback_params.nil?
			puts 'callback_params:nil'
		else
			puts 'callback_params:' + callback_params.to_s
			package_id = callback_params["package_id"]
		end
		if response.nil?
			puts 'response:nil'
			puts 'result:nil'
			puts 'code:nil'
			puts 'message:nil'
		else
			puts 'response:' + response
			resJSON = JSON.parse response
			commonHeader = resJSON["commonHeader"]
			result = commonHeader["RESULT"]
			list = resJSON["LIST"]
			code = list["code"]
			message = list["message"]
			puts 'result:' + result
			puts 'code:' + code
			puts 'message:' + message
			if (!package_id.nil? && package_id.is_a?(Numeric))
				if (code=='1')
					Package.find(package_id).update(status: :done)
				else
					Package.find(package_id).update(status: :failed)
				end
			else
				puts 'package_id:nil or not Numeric'
			end
		end
	end
end