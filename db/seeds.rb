# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rails db:seed command (or created alongside the database with db:setup).
#
# Examples:
#
#   movies = Movie.create([{ name: 'Star Wars' }, { name: 'Lord of the Rings' }])
#   Character.create(name: 'Luke', movie: movies.first)
# User.where(username: 'superadmin').first_or_create(username: 'superadmin', password: 'pwd12345', name: 'superadmin', role: 'superadmin', email: 'email@emal.com')

# unit = Unit.where(no: '20000000').first_or_create(name: '物流分公司', short_name: '物流分公司', level:1)
# User.where(username: 'unitadmin').first_or_create(username: 'unitadmin', password: 'unitadmin12345', name: '机构管理员', role: 'unitadmin', unit_id: unit.id, email: 'email@email.com')
# User.where(username: 'user').first_or_create(username: 'user', password: 'user12345', name: '普通用户', role: 'user', unit_id: unit.id)
Package.update_all(unit_id: Unit.first.id)
Order.update_all(unit_id: Unit.first.id)
InterfaceLog.update_all(unit_id: Unit.first.id)
InterfaceSender.update_all(unit_id: Unit.first.id)
Unit.first.update(no: '0001')
unit_gy = Unit.where(no: '0002').first_or_create(name: '国药分公司', short_name: '国药分公司', level:1)
User.where(username: 'unitadmingy').first_or_create(username: 'unitadmingy', password: 'unitadmingy12345', name: '机构管理员', role: 'unitadmin', unit_id: unit_gy.id)
