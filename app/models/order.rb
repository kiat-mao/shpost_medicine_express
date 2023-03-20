class Order < ApplicationRecord
	has_many :bags, dependent: :destroy
	has_many :commodities, dependent: :destroy
	belongs_to :package, optional: true
	belongs_to :unit, optional: true

	validates_presence_of :order_no, :message => '订单号不能为空'
	validates_uniqueness_of :order_no, :message => '订单号已存在'

	enum status: {waiting: 'waiting', packaged: 'packaged', cancelled: 'cancelled'}
	STATUS_NAME = { waiting: '未装箱', packaged: '已装箱', cancelled: '已取消'}

	enum interface_status: {interface_waiting: 'interface_waiting', need_send: 'need_send', to_send: 'to_send', failed: 'failed', done: 'done'}
	INTERFACE_STATUS_NAME = {interface_waiting: '待发送', need_send: '可以发送', to_send: '发送队列中', failed: '发送失败', done: '发送成功'}

	ORDER_MODE_NAME =  {B2B: 'B2B', B2C: 'B2C'}

	enum address_status: {address_waiting: 'address_waiting', address_success: 'address_success', address_failed: 'address_failed', address_noparse: 'address_noparse', address_parseing: 'address_parseing'}
	ADDRESS_STATUS_NAME = {address_waiting: '待解析', address_success: '解析成功', address_failed: '解析失败', address_noparse: '不解析', address_parseing: '解析中'}

	def status_name
		status.blank? ? "" : Order::STATUS_NAME["#{status}".to_sym]
	end

	def interface_status_name
		interface_status.blank? ? "" : Order::INTERFACE_STATUS_NAME["#{interface_status}".to_sym]
	end

	def order_mode_name
		order_mode.blank? ? "" : Order::ORDER_MODE_NAME["#{order_mode}".to_sym]
	end

	def freight_name
	  if freight
	    name = "是"
	  else
	    name = "否"
	  end
	end

	def cancel_order!
		if order_mode.eql? 'B2B'
			cancelled! if waiting?
		elsif order_mode.eql? 'B2C'
			Order.waiting.where(site_no: site_no).where(order_mode: 'B2C').update_all(status: Order::statuses[:cancelled])
		end
	end
	
	def address_status_name
		address_status.blank? ? "" : Order::ADDRESS_STATUS_NAME["#{address_status}".to_sym]
	end

	def self.order_push(context_hash, unit = nil)
		order = Order.find_or_initialize_by(order_no: context_hash['ORDER_NO'], unit: unit)

		order.unit = unit 

		context_hash.keys.each do |key|
			next if key.eql? "COMMODITIES"

			if order.respond_to? "#{key.downcase}="
				order.send "#{key.downcase}=", context_hash[key]
			end
		end
		
		order.bags.destroy_all
		order.commodities.destroy_all
		order.waiting!

		packages_context = context_hash["PACKAGES"]
		bags = packages_context.each{|x| order.bags.new(bag_no: x)}

		order.bag_list = order.bags.map{|x| x.bag_no}.join(',')


		commodities_context = context_hash["COMMODITIES"]
		if !commodities_context.blank?
			commodities_context.each do |commodity|
				c = order.commodities.new
				commodity.keys.each do |key|
					if c.respond_to? "#{key.downcase}="
						c.send "#{key.downcase}=", commodity[key]
					end
				end
			end
		end

		order.address_status = Order.address_statuses[:address_waiting]
		order.interface_waiting! 
		# order.waiting!
	end

	def self.fix_address(filename, unit_id)
		instance=nil
		rowarr = [] 
		direct = "#{Rails.root}/public/download/"

    if !File.exist?(direct)
      Dir.mkdir(direct)          
    end
    
    file_path = direct + filename

    if file_path.try :end_with?, '.xlsx'
      instance= Roo::Excelx.new(file_path)
    elsif file_path.try :end_with?, '.xls'
      instance= Roo::Excel.new(file_path)
    elsif file_path.try :end_with?, '.csv'
      instance= Roo::CSV.new(file_path)
    end

    instance.default_sheet = instance.sheets.first
    # title_row = instance.row(1)
    # order_no_index = title_row.index("体检号").blank? ? 0 : title_row.index("体检号")
    # address_index = title_row.index("地址").blank? ? 2 : title_row.index("地址")

    2.upto(instance.last_row) do |line|
      begin
      	rowarr = instance.row(line)
      	order_no = rowarr[0].to_s.split('.0')[0]
      	address = rowarr[2]
      	# order_no = rowarr[order_no_index].to_s.split('.0')[0]
      	# address = rowarr[address_index]

      	Order.create! order_no: order_no, receiver_addr:address, unit_id: unit_id

      rescue => e
        raise e
      ensure
        line = line + 1
      end
    end
	end

	def self.export_address(unit_id)
		direct = "#{Rails.root}/public/download/"
		file_path = direct + "fix_address_#{Time.now.strftime("%Y%m%d")}.xls"
		#start_id = Order.find_by(order_no: start_no).id
		#end_id = Order.find_by(order_no: end_no).id
		#orders = Order.where("id>=? and id<=?", start_id, end_id)
		orders = Order.where(unit_id: unit_id).order(:order_no)

		book = Spreadsheet::Workbook.new  
    sheet1 = book.create_worksheet :name => "sheet1"  
  
    blue = Spreadsheet::Format.new :color => :blue, :weight => :bold, :size => 10  
    sheet1.row(0).default_format = blue  

    sheet1.row(0).concat %w{体检号 修正 省 市 区（县）}  
    count_row = 1
    orders.each do |obj|  
    	sheet1[count_row,0]=obj.order_no
    	sheet1[count_row,1]=obj.receiver_addr
    	sheet1[count_row,2]=obj.receiver_province
    	sheet1[count_row,3]=obj.receiver_city
    	sheet1[count_row,4]=obj.receiver_district
    	count_row += 1
    end
    book.write file_path

	end

	
end
