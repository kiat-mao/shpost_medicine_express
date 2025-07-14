class TmsInterfaceSender < ActiveRecord::Base

	def self.order_trace_schedule
		xydConfig = Rails.application.config_for(:xyd)
		gy_unit_no = I18n.t('unit_no.gy').to_s
		gy_units = Unit.where no: gy_unit_no
		orders = Order.where(interface_status: :need_send, unit: gy_units)
		orders.each_with_index do |order, i|
			if order.package.blank?
				next
			end
			self.order_trace_order_interface_sender_initialize order
		end
	end

	def self.order_trace_order_interface_sender_initialize(order)
		tmsConfig = Rails.application.config_for(:tms)
		body = self.order_trace_request_body_generate(order, tmsConfig)
		header = self.order_trace_request_head_generate(body, tmsConfig)
		args = Hash.new
		callback_params = Hash.new
		callback_params["package_id"] = order.package.id
		callback_params["order_id"] = order.id
		args[:callback_params] = callback_params.to_json
		args[:url] = tmsConfig[:order_trace_url]
		args[:header] = header
		args[:parent_id] = order.id
		args[:unit_id] = order.unit_id
		InterfaceSender.interface_sender_initialize("tms_order_trace", body, args)
		# 更新Order状态
		order.update interface_status: :to_send
	end

	def self.order_trace_request_head_generate(body, tmsConfig)
		args = Hash.new
		args["Content-Type"] = "application/json;charset=utf-8"

		# date = Time.now.utc.strftime("%a, %d %b %Y %H:%M:%S GMT")
		date = "2025-07-11 16:00:00 GMT".to_time.utc.strftime("%a, %d %b %Y %H:%M:%S GMT") # For testing, use a fixed date
		args[:Date] = date

		args[:"X-HMAC-ACCESS-KEY"] = tmsConfig[:appKey]

		# args[:dataDigest] = data_digest_generate(tmsConfig[:appSercret], args[:timestamp], body)
		# args[:from] = tmsConfig[:from]
		sign_body = "POST\n#{tmsConfig[:path]}\n\n#{tmsConfig[:appKey]}\n#{date}\n"

		args[:"X-HMAC-SIGNATURE"] = self.hmac_sha256_and_base_64_hex_generate(tmsConfig[:appSercret], sign_body).strip

		args[:"X-HMAC-ALGORITHM"] = "hmac-sha256"
		
		args[:"X-HMAC-DIGEST"] = self.hmac_sha256_and_base_64_hex_generate(tmsConfig[:appSercret], body).strip

		puts args
		return args.to_json
	end

	def self.hmac_sha256_and_base_64_hex_generate(key, data)
		return self.base_64_hex_generate(self.hmac_sha256_generate(key, data))
	end

	def self.base_64_hex_generate(data)
		# This method encodes the given data into Base64 format.
		# Ensure Base64 is available
		unless defined?(Base64)
			raise "Base64 is not available. Please install the Base64 gem."
		end

		binary_data = [data].pack('H*')
		# Example of encoding data to Base64
		base64_data = Base64.strict_encode64(binary_data)
		puts "Base64 Encoded Data: #{base64_data}"
		return base64_data
	end

	def self.hmac_sha256_generate(key, data)
		# This method generates an HMAC-SHA256 signature for the given key and data.
		# It uses the OpenSSL library to create the digest.
		# Ensure OpenSSL is available
		unless defined?(OpenSSL::Digest) && defined?(OpenSSL::HMAC)
			raise "OpenSSL is not available. Please install the OpenSSL gem."
		end
		# Example of generating HMAC-SHA256 signature

		digest = OpenSSL::Digest.new('sha256')
		hmac = OpenSSL::HMAC.hexdigest(digest, key, data)
		puts "HMAC-SHA256: #{hmac}"
		return hmac
	end

	def self.data_digest_generate(appSercret, timestamp, body)
		md5 = Digest::MD5.hexdigest(appSercret + timestamp + body)
		sha1 = Digest::SHA1.hexdigest(md5)
		return sha1
	end

	def self.order_trace_request_body_generate(order, tmsConfig)
		now_time = Time.new

		orderInfo = {}
		orderInfo["orderCode"] = order.order_no
		orderInfo["ecNo"] = order.ec_no
		orderInfo["waybillNo"] = order.package.express_no
		orderInfo["operationTime"] = (order.updated_at.to_f*1000).to_i.to_s
		orderInfo["volume"] = order.package.volume.to_f #包裹体积（立方厘米）
		orderInfo["weight"] = order.package.weight.to_f/1000 #包裹重量（公斤）
		orderInfo["amount"] = order.package.price.to_f #元

		orderInfo.to_json
	end

	def self.order_trace_callback_method(response, callback_params)
		puts 'tms order_trace_callback_method!!'
		package_id = nil
		order_id = nil
		if callback_params.nil?
			puts 'callback_params:nil'
		else
			puts 'callback_params:' + callback_params.to_s
			package_id = callback_params["package_id"]
			order_id = callback_params["order_id"]
		end
		if response.nil?
			puts 'response:nil'
			return false
		else
			puts 'response:' + response
			resJSON = JSON.parse response
			code = resJSON["code"]
			puts 'code:' + code
			if (!order_id.nil? && order_id.is_a?(Numeric))
				if (code=='0')
					Order.find(order_id).update(interface_status: :done)
					return true
				else
					Order.find(order_id).update(interface_status: :failed)
					return false
				end
			else
				puts 'order_id:nil or not Numeric'
				return false
			end
		end
	end
end