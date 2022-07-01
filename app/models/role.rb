class Role < ApplicationRecord
  belongs_to :user
  belongs_to :unit

  validates_presence_of :user_id, :unit_id, :role, :message => '不能为空字符'
  validates_uniqueness_of :user_id, scope: [:unit_id, :role], :message => '该角色在该仓库中角色已存在'
  
  ROLE = { admin: '管理员', purchase: '采购员', sorter: '库存管理员', order: '订单管理员'}

  def self.get_units_by_user_id(user_id)
    Role.where("user_id = ?", user_id).group(:unit_id)
  end
end
	