class Bag < ApplicationRecord
	belongs_to :order, optional: true
	has_one :package, through: :order

	# before_save :set_bag_list_to_order

	validates_presence_of :bag_no, :message => '袋子号不能为空'
 	# validates_uniqueness_of :bag_no, :message => '袋子号已存在'

 	# def set_bag_list_to_order
 	# 	self.order.update bag_list: self.order.bag_list.blank? ? self.bag_no : self.order.bag_list+","+self.bag_no
  # 	end
end