class Package < ApplicationRecord
	has_many :orders
	has_many :bags, through: :orders
	belongs_to :user
	belongs_to :unit

	validates_presence_of :package_no, :message => '箱号不能为空'
 	validates_uniqueness_of :package_no, :message => '箱号已存在'

 	enum status: {waiting: 'waiting', to_send: 'to_send', failed: 'failed', done: 'done', cancelled: 'cancelled'}
 	STATUS_NAME = { waiting: '未发送', to_send: '待发送', failed: '发送失败', done: '已发送', cancelled: '已作废'}

 	# enum pkp: {pkp_waiting: 'pkp_waiting', pkp_done: 'pkp_done'}
 	# PKP_NAME = {pkp_waiting: '未收寄', pkp_done: '收寄完成'}
 	enum pkp: {pkp_done: 'pkp_done'}
 	PKP_NAME = {pkp_done: '允许收寄'}


	# 年月日+用户id+当天该用户装箱计数,Eg:”20220707-3-1”
 	def self.new_package_no(current_user)		
 		new_package_no = Date.today.strftime('%Y%m%d') + "-" + current_user.id.to_s + "-" + self.get_package_no_by_user(current_user).to_s
 	end

	# 每日每个工号自动从“编号1”开始装箱计数
 	def self.get_package_no_by_user(current_user)
    num =  Package.where(user_id: current_user.id).where("packed_at>=?", Date.today).count
 		package_no = num.zero? ? 1 : (num + 1)
 	end

 	def get_all_bags
 		all_bags = 0

 		if !self.orders.blank?
	 		if self.unit.no == I18n.t('unit_no.sy')
		 		self.orders.each do |o|
		 			all_bags += o.bags.count
		 		end
		 	elsif self.unit.no == I18n.t('unit_no.gy')
		 		all_bags = self.orders.map{|o| o.bag_list}.uniq.count
		 	end
		end
	 			
 		return all_bags
 	end

 	def status_name
 		status.blank? ? "" : Package::STATUS_NAME["#{status}".to_sym]
 	end

 	def cancelled
 		if self.unit.no == I18n.t('unit_no.sy')
 			oids = Bag.where(belong_package_id: self.id).map{|b| b.order_id}.compact
 			Bag.where(belong_package_id: self.id).update_all belong_package_id: nil
 			Order.where(id: oids).each do |o|
 				old_package_list = o.package_list.split(",")
 				old_package_list.delete(self.package_no)
 				new_package_list = old_package_list.join(",")
 				o.update package_list: new_package_list, status: "waiting"
 			end			
 		elsif self.unit.no == I18n.t('unit_no.gy')
 			self.orders.update_all status: "waiting", package_id: nil
 		end
		self.update status: "cancelled"
	end

	def pkp_name
 		pkp.blank? ? "" : Package::PKP_NAME["#{pkp}".to_sym]
 	end

  # 面单打印分拣码
 	def self.get_sorting_code(route_code)
 		sorting_code = ""
 		if !route_code.blank?
 			rcode_pre = route_code.split("-")[0]
 			rcode = route_code.split("-")[2]
 			# 格口码第一栏090,091表示是上海的，只有090,091开头才记分拣码,否则为空
 			if ["090","091"].include?rcode_pre
	 			I18n.t('sorting_code').each do |k,v|
	 				if v.include?rcode
	 					sorting_code = k
	 					break
	 				end
	 			end
	 		end
 		end
 		return sorting_code
 	end


end
