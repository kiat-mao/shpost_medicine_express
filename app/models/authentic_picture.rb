class AuthenticPicture < ApplicationRecord
	enum status: {waiting: 'waiting', sending: 'sending', sended: 'sended', authentic: 'authentic', failed: 'failed'}
	STATUS_NAME = { waiting: '待发送', sending: '获得真迹中', sended: '已发送上药', authentic: '获得真迹成功', failed: '发送失败' }

	def self.clean_interface_sends
		InterfaceSender.where(interface_code: ['image_push', 'obtain_authentic_picture']).where(status: 'success').destroy_all
	end
	
	def self.init_authentic_pictures_15days_ago
		start_date = Date.today - 15.day
    end_date = Date.today - 14.day
		init_authentic_pictures(start_date, end_date)
	end

	def self.init_authentic_pictures_yesterday
		start_date = Date.today - 1.day
    end_date = Date.today
		init_authentic_pictures(start_date, end_date)
	end

	def self.init_authentic_pictures(start_date, end_date)
		puts("#{Time.now}  init_authentic_pictures,  start")
		
    pkp_waybill_bases = PkpWaybillBase.where(sender_no: I18n.t(:sy_sender_no)).where("biz_occur_date >= ? and biz_occur_date < ?", start_date, end_date)
    if end_date - start_date <= 1
      pkp_waybill_bases = pkp_waybill_bases.where(created_day: start_date.strftime("%d"))
    else
      days = (start_date...end_date).to_a.map{|x| x.strftime("%d")}
      pkp_waybill_bases = pkp_waybill_bases.where(created_day: days)
    end

    ActiveRecord::Base.transaction do
      pkp_waybill_bases.find_each(batch_size: 500) do |pkp_waybill_base|
        AuthenticPicture.init_authentic_picture(pkp_waybill_base)
      end
    end

    puts("#{Time.now}, init_authentic_pictures,  count: #{pkp_waybill_bases.size}, end")
	end

	def self.init_authentic_picture(pkp_waybill_base)
		authentic_picture = AuthenticPicture.find_or_initialize_by(express_no: pkp_waybill_base.waybill_no)
		authentic_picture.posting_date = pkp_waybill_base.biz_occur_date
		authentic_picture.status = 'waiting'
		authentic_picture.sended_times = 0
		authentic_picture.next_time = Date.today + 5.day#考虑真迹未取到的可能性
		authentic_picture.save!
	end

	def self.init_obtain_authentic_pictures_and_send
		puts("#{Time.now}  send_authentic_pictures,  start")
		authentic_pictures = self.where(status: 'waiting').where("next_time <= ? ", Time.now)
		size = authentic_pictures.count
		authentic_pictures.find_each(batch_size: 2000) do |authentic_picture|
			interface_sender = XydInterfaceSender.obtain_authentic_picture_interface_sender_initialize(authentic_picture)
			# interface_sender.interface_send
			# authentic_picture.update!(status: 'sended')
		end
		
		puts("#{Time.now}  send_authentic_pictures, count: #{size},  end")
	end

end