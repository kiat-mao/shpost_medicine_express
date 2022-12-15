class WaybillSender

  def self.waybill_schedule
    unit = Unit.find_by(no: I18n.t('unit_no.gy').to_s)
    packages = Package.pkp_done.where(unit: unit).where(weight: nil)
    packages.each do |package|
      self.waybill_query package
    end
  end

  def self.waybill_schedule_offline
    unit = Unit.find_by(no: I18n.t('unit_no.gy').to_s)
    packages = Package.where(pkp: nil).where(unit: unit).where("created_at < ? ", Time.now - 15.minute)
    packages.each do |package|
      package.update(pkp:  Package.pkps[:pkp_done])
      package.orders.update_all(interface_status: Order.interface_statuses[:need_send])
    end
  end

  def self.waybill_query(package)
		InterfaceSender.interface_sender_initialize("waybill_query", {mail_no: package.express_no}.to_json, {parent_id: package.id, unit_id: package.unit_id, business_code: package.express_no})
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