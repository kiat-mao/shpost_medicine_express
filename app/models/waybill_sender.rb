class WaybillSender

  def self.waybill_schedule
    unit = Unit.find_by(no: I18n.t('unit_no.gy').to_s)
    packages = Package.pkp_done.where(unit: unit).where(wegith: nil)
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