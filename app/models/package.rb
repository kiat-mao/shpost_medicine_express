class Package < ApplicationRecord
	has_many :orders
	has_many :bags, through: :orders

	validates_presence_of :package_no, :message => '箱号不能为空'
 	validates_uniqueness_of :package_no, :message => '箱号已存在'

 	enum status: {waiting: 'waiting', done: 'done', cancelled: 'cancelled'}
end