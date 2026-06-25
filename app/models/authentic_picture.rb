class AuthenticPicture < ApplicationRecord
	enum status: {waiting: 'waiting', sending: 'sending', sended: 'sended', authentic: 'authentic', failed: 'failed'}
	STATUS_NAME = { waiting: '待发送', sending: '获得真迹中', authentic: '获得真迹成功', sended: '已发送上药', failed: '发送失败' }

	def self.clean_interface_sends
		InterfaceSender.where(interface_code: ['image_push', 'obtain_authentic_picture']).where(status: 'success').destroy_all
	end

	def self.clean_duplicate_obtain_authentic_picture_senders
		# 1. 找到所有需要处理的记录
		records = InterfaceSender.where(interface_code: 'obtain_authentic_picture', status: 'waiting')
														.order(:parent_id, :created_at)  # 按 parent_id 和创建时间排序
														.to_a

		# 2. 按 parent_id 分组
		grouped = records.group_by(&:parent_id)

		# 3. 遍历每组，保留第一个（即最早创建的），删除后面的
		deleted_count = 0
		grouped.each do |parent_id, group|
			next if group.size <= 1
			# 保留第一条
			keep = group.first
			# 其余删除
			to_delete = group[1..-1]
			ids = to_delete.map(&:id)
			InterfaceSender.where(id: ids).delete_all  # 直接删除，跳过回调（如果需要回调，用 destroy_all）
			deleted_count += ids.size
			puts "已清理 parent_id=#{parent_id} 的 #{ids.size} 条重复记录，保留 ID=#{keep.id}"
		end

		puts "共清理 #{deleted_count} 条重复记录"
	end
	
	def self.init_authentic_pictures_recently
		start_date = Date.today - 12.day
    end_date = Date.today - 11.day
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
		if authentic_picture.new_record?
			authentic_picture.posting_date = pkp_waybill_base.biz_occur_date
			authentic_picture.status = 'waiting'
			authentic_picture.sended_times = 0
			authentic_picture.next_time = Date.today + 1.day#考虑真迹未取到的可能性
		end
		authentic_picture.save!
	end

	def self.init_obtain_authentic_pictures_and_send
		puts("#{Time.now}  send_authentic_pictures,  start")
		authentic_pictures = self.where(status: 'waiting').where("next_time <= ? ", Time.now)
		size = authentic_pictures.count

		waiting_image_push_size = InterfaceSender.where(status: 'waiting').where(interface_code: 'image_push').count
		
		return if waiting_image_push_size >= 2000

		authentic_pictures.find_each(batch_size: 2000) do |authentic_picture|
			interface_sender = XydInterfaceSender.obtain_authentic_picture_interface_sender_initialize(authentic_picture)
			interface_sender.interface_send
			# authentic_picture.update!(status: 'sended')
		end
		
		puts("#{Time.now}  send_authentic_pictures, count: #{size},  end")
	end

end