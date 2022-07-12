class Bag < ApplicationRecord
	belongs_to :order, optional: true
	has_one :package, through: :order

	validates_presence_of :bag_no, :message => '袋子号不能为空'
 	validates_uniqueness_of :bag_no, :message => '袋子号已存在'
end