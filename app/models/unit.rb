class Unit < ApplicationRecord
  has_many :users, dependent: :destroy
  belongs_to :parent_unit, :class_name => 'Unit', :foreign_key => 'parent_id', optional: true
  has_many :child_units, :class_name => 'Unit', :foreign_key => 'parent_id',:dependent => :destroy

  before_save :set_level
  # has_many :tarrif_items, dependent: :destroy
  # has_many :tarrif_packages, dependent: :destroy

  validates_presence_of :name, :message => '不能为空'
  validates_uniqueness_of :name, :message => '该单位已存在'

  validates_uniqueness_of :short_name, :message => '该缩写已存在', if: :short_name?

  validates_presence_of :parent_id, :message => '不能为空', unless: :is_parent?

  LEVEL = {1 => 1, 2 => 2}
  # TYPE = {branch: '区分公司', delivery: '寄递事业部', postbuy: '国际邮购'}
  # TYPE_BRANCH = {branch: '区分公司'}
  # DELIVERY = Unit.find_by(unit_type: 'delivery') 
  # POSTBUY = Unit.find_by(unit_type: 'postbuy') 
  def unit_type_name
    unit_type.blank? ? "" : self.class.human_attribute_name("unit_type_#{unit_type}")
  end
  
  
  def can_destroy?
		if self.child_units.blank? && self.users.blank?
			return true
		else
			return false
		end
  end

  def is_parent?
    level.blank? || level <= 1 
  end

  def set_level
    if ! parent_unit.blank?
      self.level = (parent_unit.level||1) + 1
    else
      self.level = 1
    end
  end
  # def delivery?
  #   (unit_type.eql? 'delivery') ? true : false
  # end
  # def postbuy?
  #   (unit_type.eql? 'postbuy') ? true : false
  # end
end
