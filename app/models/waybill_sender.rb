class WaybillSender

  def self.waybill_schedule
    xydConfig = Rails.application.config_for(:xyd)
    gy_unit_no = xydConfig[:gy_unit_no]
    gy_units = Unit.where no: gy_unit_no
    packages = Packaged.pkp_done.where(unit: gy_units)
    packages.each do |package|
      self.waybill_query package
    end
  end

  def self.waybill_query(mail_no)
		InterfaceSender.interface_sender_initialize("waybill_query", {mail_no: mail_no}.to_json)
	end

	def self.waybill_callback(response, callback_params)
		# binding.pry
		if ! response.blank?	
			response_json = JSON.parse response
      if response_json["FLAG"].eql? "success"
        package = Package.find_by_express_no(response_json["MAIL_NO"])

        if ! package.blank?
          package.update!(weight: response_json['WEIGHT'], price: response_json['PRICE'])
          package.orders.update_all(interface_status: Order.interface_statuses[:need_send])
        end
      end
		end
	end
end