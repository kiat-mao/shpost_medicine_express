class Package < ApplicationRecord
	has_many :orders
	has_many :bags, through: :orders
	belongs_to :user

	validates_presence_of :package_no, :message => '箱号不能为空'
 	validates_uniqueness_of :package_no, :message => '箱号已存在'

 	enum status: {waiting: 'waiting', done: 'done', cancelled: 'cancelled', failed: 'failed'}
 	STATUS_NAME = { waiting: '未发送', done: '已发送', cancelled: '已作废', failed: '发送失败'}

	# 年月日+用户id+当天该用户装箱计数,Eg:”20220707-3-1”
 	def self.new_package_no(current_user)		
 		new_package_no = Date.today.strftime('%Y%m%d') + "-" + current_user.id.to_s + "-" + self.get_package_no_by_user(current_user).to_s
 	end

	# 每日每个工号自动从“编号1”开始装箱计数
 	def self.get_package_no_by_user(current_user)
 		package_no = Package.where(user_id: current_user.id).where("date(packed_at)=?", Date.today).blank? ? 1 : Package.where(user_id: current_user.id).where("date(packed_at)=?", Date.today).last.package_no.split("-").last.to_i+1
 	end

 	def get_all_bags
 		all_bags = 0
 		self.orders.each do |o|
 			all_bags += o.bags.count
 		end
 		return all_bags
 	end

 	def status_name
 		status.blank? ? "" : Package::STATUS_NAME["#{status}".to_sym]
 	end
end