class PackagesController < ApplicationController
  load_and_authorize_resource :package
  protect_from_forgery :except => [:tkzd,:zxqd]

  # GET /packages
  # GET /packages.json
  def index
  	@no = params[:no]
  	if @no.blank?
	  	@packages = Package.accessible_by(current_ability)
	  	if params[:grid].blank?
		  	@packages = @packages.where("packed_at>=?", Date.today)
		  end
		else
			@packages = Package.accessible_by(current_ability).joins(:orders).where("orders.prescription_no = ? or orders.social_no = ? or orders.receiver_phone = ?", @no, @no, @no)	
		end
	  
    @packages_grid = initialize_grid(@packages,
         :order => 'packed_at',
         :order_direction => 'asc', 
         :per_page => params[:page_size])
  end

  def tkzd
  	@result = []
  	@package_id = params[:package_id]
  	if !params[:package_id].blank?
  		@result << Package.find(params[:package_id])
  	else
	  	if !params[:selected].blank?
	      selected = params[:selected].split(",")
	       
	      until selected.blank? do 
	        @result += Package.where(id:selected.pop(1000))
	      end
	  	else
	      flash[:alert] = "请勾选需要打印的箱子"
	      respond_to do |format|
	        format.html { redirect_to request.referer }
	        format.json { head :no_content }
	      end
	    end
    end
  end

	def zxqd
		@result = []

  	if !params[:package_id].blank?
  		@result << Package.find(params[:package_id])
  	else
  		if !params[:selected].blank?
	      selected = params[:selected].split(",")
	       
	      until selected.blank? do 
	        @result += Package.where(id:selected.pop(1000))
	      end
	  	else
	      flash[:alert] = "请勾选需要打印的箱子"
	      respond_to do |format|
	        format.html { redirect_to request.referer }
	        format.json { head :no_content }
	      end
	    end
  	end
	end

	def send_sy
		packages = []

		if params[:grid] && params[:grid][:selected]
  		selected = params[:grid][:selected]
	       
	    until selected.blank? do 
	      packages = Package.where(id:selected.pop(1000))
	      packages.each do |p|
	      	if (["waiting", "failed"].include?p.status)
	      		SoaInterfaceSender.order_trace_interface_sender_initialize(p)
	      	end
	      end
	    end
	    flash[:notice] = "已回传上药"	    
	  else
	  	flash[:alert] = "请勾选需要回传上药的箱子"
	  end   
	  
  	respond_to do |format|
      format.html { redirect_to request.referer }
      format.json { head :no_content }
    end
	end

	def cancelled
		if ["waiting", "failed", "to_send"].include?@package.status
			@package.cancelled
		end

		respond_to do |format|
			flash[:notice] = "箱子已作废"
      format.html { redirect_to request.referer }
      format.json { head :no_content }
    end
	end

  def scan
  	@package_no = Package.get_package_no_by_user(current_user)
  	@bag_amount = 0
  end

  def find_bag_result
  	@bag_no = params[:bag_no]
  	@site_no = params[:site_no]
  	@order_bags = params[:order_bags]
  	@err_msg = ""
  	@bag_amount = params[:bag_amount].to_i
 	
  	bag = Bag.find_by(bag_no: @bag_no)
		if bag.blank? || (bag.order.try(:unit_id) != current_user.unit_id.to_s)
			@err_msg = "包裹无信息"
		else
			if !Bag.joins(:order).joins(:order=>:package).where("bags.bag_no=? and orders.status=? and packages.packed_at>=? and packages.packed_at<?", @bag_no, "packaged", Time.now-1.year, Time.now).blank?
				@err_msg = "包裹已装箱，不可二次装箱"
			else
				if (!@site_no.blank?) && (!@site_no.eql?bag.order.site_no)
  				@err_msg = "非同一站点包裹"
  			else
  				if @site_no.blank?
						@site_no = bag.order.site_no
  				end
  				# “订单号1：袋子号1，袋子号2，袋子号3|订单号2：袋子号4，袋子号5...”
  				if !@order_bags.blank?
  					if @order_bags.include?bag.order.order_no
	  					order_bags_arr = @order_bags.split("|")
	  					i=0
	  					order_bags_arr.each do |o|
	  						if o.include?bag.order.order_no
	  							order_bags_arr[i] = o + "," + @bag_no
	  							@order_bags = order_bags_arr.join("|")
	  							break
	  						end
	  						i += 1
	  					end
	  				else
	  					@order_bags += "|" + bag.order.order_no + ":" + @bag_no
	  				end
	  			else
	  				@order_bags = bag.order.order_no + ":" + @bag_no
	  			end
	  			@bag_amount += 1
	  		end
  		end
  	end
  	# binding.pry
	end

	def do_packaged
		@order_bags = params[:order_bags]
  	@err_msg = ""
  	@package_id = params[:package_id]
  	@is_packaged = "0"
  	
  	if !@package_id.blank?
  		msg = package_send(Package.find(@package_id))
			@err_msg = msg if !msg.eql?"成功"	
			@is_packaged = "1"
  	else
	  	if !@order_bags.blank?
		  	uneql_order_no = uneql_order_no(@order_bags)
		  	if !uneql_order_no.blank?
		  		@err_msg = "订单号#{uneql_order_no}，有袋子未扫描"
		  	else
		  		order_list = get_orders(@order_bags)
		  		bag_list = get_bags(@order_bags)
	  			package_no = Package.new_package_no(current_user)
					@package = Package.create package_no: package_no, status: 'waiting', packed_at: Time.now, user_id: current_user.id, order_list: order_list, bag_list: bag_list, unit_id: current_user.unit_id
					@package_id = @package.id
					Order.where(order_no: order_list).update_all package_id: @package.id, status: "packaged"
					@is_packaged = "1"
					msg = package_send(@package)
					@err_msg = msg if !msg.eql?"成功"			
				end
			end		
		end
	end

	def uneql_order_no(order_bags)
		# “订单号1：袋子号1，袋子号2，袋子号3|订单号2：袋子号4，袋子号5...”
		uneql_order_no = ""
		order_bags_arr = @order_bags.split("|")
		order_bags_arr.each do |o|
			obarr = o.split(":")
			if Order.find_by(order_no: obarr[0]).bags.count > obarr[1].split(",").count
				uneql_order_no = obarr[0]
				break
			end
		end
		return uneql_order_no
	end

	def get_orders(order_bags)
		# “订单号1：袋子号1，袋子号2，袋子号3|订单号2：袋子号4，袋子号5...”
		order_nos = []
		
		order_bags.split("|").each do |o|
			order_nos << o.split(":")[0]
		end
		return order_nos
	end

	def get_bags(order_bags)
		# “订单号1：袋子号1，袋子号2，袋子号3|订单号2：袋子号4，袋子号5...”
		bag_nos = []
		
		order_bags.split("|").each do |o|
			bag_nos += o.split(":")[1].split(",")
		end
		return bag_nos
	end

	def send_xyd
		msg = package_send(@package)
		
		respond_to do |format|
			if msg.eql?"成功"
				flash[:notice] = "获取邮件号、格口码成功"				
			else
				flash[:alert] = msg
			end
      format.html { redirect_to request.referer }
      format.json { head :no_content }
    end
	end

	# 发送新一代接口，获取邮件号，格口码,返回'成功'或出错信息
	def package_send(package)
		interface_sender = XydInterfaceSender.order_create_interface_sender_initialize(package)
		interface_sender.interface_send(10)
		msg = XydInterfaceSender.get_response_message(interface_sender)
		# package.update express_no: "e000001", route_code: "r000001"
		# msg = "成功"
		return msg			
	end

	def package_export
		packages = filter_packages(@packages,params)
    
    if packages.blank?
      flash[:alert] = "无装箱数据"
      redirect_to :action => 'index'
    else
      send_data(package_xls_content_for(packages.order(:packed_at)), :type => "text/excel;charset=utf-8; header=present", :filename => "装箱数据_#{Time.now.strftime("%Y%m%d")}.xls")  
    end
	end

	def filter_packages(packages, params)
    start_date = nil
    end_date = nil
    packages = packages.left_joins(:user)

    if !params[:grid].blank?
      if !params[:grid][:f].blank?
        params_f = params[:grid][:f]
        if !params_f[:package_no].blank?
          packages = packages.where("package_no like ?", '%#{params_f[:package_no]}%')
        end
        if !params_f[:express_no].blank?
        	packages = packages.where("express_no like ?", '%#{params_f[:express_no]}%')
        end
        if !params_f[:route_code].blank?
        	packages = packages.where("route_code like ?", '%#{params_f[:route_code]}%')
        end
        if !params_f[:order_list].blank?
        	packages = packages.where("order_list like ?", '%#{params_f[:order_list]}%')
        end
        if !params_f[:bag_list].blank?
        	packages = packages.where("bag_list like ?", '%#{params_f[:bag_list]}%')
        end
        if !params_f[:status].blank?
          if !params_f[:status][0].blank?
          	packages = packages.where(status: params_f[:status][0])
          end
        end
        if !params_f['users.name'].blank?
        	uname = params_f['users.name']
        	packages = packages.where("users.name like ?", '%#{uname}%')
        end
        if params_f[:packed_at][:fr].blank? && params_f[:packed_at][:to].blank?
        	start_date = Date.today
	      	end_date = Date.today+1.day
	      else
	        start_date = params_f[:packed_at][:fr] if !params_f[:packed_at][:fr].blank?
	      	end_date = params_f[:packed_at][:to].to_date+1.day if !params_f[:packed_at][:to].blank?
	      end

	      if !start_date.blank?
	      	packages = packages.where("packed_at >= ?", start_date)
	      end
		    if !end_date.blank?
		    	packages = packages.where("packed_at < ?", end_date)
		    end
	    end
	  end
	  
	  return packages
	end

	def package_xls_content_for(objs)  
    xls_report = StringIO.new  
    book = Spreadsheet::Workbook.new  
    sheet1 = book.create_worksheet :name => "装箱数据"  
  
    blue = Spreadsheet::Format.new :color => :blue, :weight => :bold, :size => 10  
    sheet1.row(0).default_format = blue  

    sheet1.row(0).concat %w{箱号 邮件号 格口码 订单号 袋子号 状态 处理用户 装箱日期}  
    count_row = 1
    objs.each do |obj|  
      sheet1[count_row,0]=obj.package_no
      sheet1[count_row,1]=obj.express_no
      sheet1[count_row,2]=obj.route_code
      sheet1[count_row,5]=obj.status_name
      sheet1[count_row,6]=obj.user.try(:name)
      sheet1[count_row,7]=obj.packed_at.strftime('%Y-%m-%d').to_s
      if obj.unit.no == I18n.t('unit_no.sy').to_s
		    if !obj.orders.blank?
		    	obj.orders.order(:order_no).each do |o|
		    		sheet1[count_row,3]=o.order_no
		    		if !o.bags.blank?
		    			o.bags.each do |b|
		    				sheet1[count_row,3]=o.order_no
		    				sheet1[count_row,4]=b.bag_no
		    				count_row += 1
		    			end
		    		end
		    	end
		    else
		    	count_row += 1
		    end  
	    elsif obj.unit.no == I18n.t('unit_no.gy').to_s		        	    
	      if !obj.orders.blank?
	      	obj.orders.order(:order_no).each do |o|
	      		sheet1[count_row,3]=o.order_no
	      		if !o.bag_list.blank?
	      			sheet1[count_row,4]=o.bag_list
	      			count_row += 1
	      		end
	      	end
	      else
	      	count_row += 1
	      end
	    end
    end

    book.write xls_report  
    xls_report.string  
  end

  def gy_scan
  	@package_no = Package.get_package_no_by_user(current_user)
  	@bag_amount = 0
  	@orde_mode = ""
  end

  def gy_find_bag_result
  	@scan_no = params[:scan_no]
  	@site_no = params[:site_no]
  	@err_msg = ""
  	@bag_amount = params[:bag_amount].to_i
  	@order_mode = params[:order_mode]
  	@orders =nil
  	@to_scan_bags = params[:to_scan_bags]
  	@scaned_orders = params[:scaned_orders]
  	@scaned_bags = params[:scaned_bags]
  	@all_scaned = "false"
  	is_bag_no = nil
  	@tmp_save_msg = ""

  	# 同一箱模式应相同，即都为B2B或都为B2C
  	# 扫第一个，order_mode为空
  	if @order_mode.blank?
  		# 用袋子号查
  		@orders = Order.joins("left outer join bags on orders.bag_list like bags.bag_no").joins(:unit).where("orders.status = ? and units.no = ? and bags.bag_no = ? and orders.address_status = ?", "waiting", I18n.t('unit_no.gy'), @scan_no, "address_success").order("bags.bag_no, orders.order_no")
  		if !@orders.blank?
  			@order_mode = @orders.first.order_mode
  			is_bag_no = true  			
  		else
  			# 用处方号，社保号，收件人电话查
  			@orders = Order.joins("left outer join bags on orders.bag_list like bags.bag_no").joins(:unit).where("orders.status = ? and units.no = ? and (orders.prescription_no = ? or orders.social_no = ? or orders.receiver_phone = ?) and orders.address_status = ?", "waiting", I18n.t('unit_no.gy'), @scan_no, @scan_no, @scan_no, "address_success").order("bags.bag_no, orders.order_no")
  			b_list = @orders.map{|o| o.bag_list}.uniq
  			@orders = Order.where(bag_list: b_list)
  			if !@orders.blank?
  				@order_mode = @orders.first.order_mode
  				is_bag_no = false
  			end
  		end 		
  	else
  		# order_mode不为空
  		@orders = Order.joins("left outer join bags on orders.bag_list like bags.bag_no").joins(:unit).where("orders.status = ? and units.no = ? and bags.bag_no = ? and orders.order_mode = ? and orders.address_status = ?", "waiting", I18n.t('unit_no.gy'), @scan_no, @order_mode, "address_success").order("bags.bag_no, orders.order_no")
  		if !@orders.blank?
  			is_bag_no = true  			
			else
				@orders = Order.joins("left outer join bags on orders.bag_list like bags.bag_no").joins(:unit).where("orders.status = ? and units.no = ? and (orders.prescription_no = ? or orders.social_no = ? or orders.receiver_phone = ?) and orders.order_mode = ? and orders.address_status = ?", "waiting", I18n.t('unit_no.gy'), @scan_no, @scan_no, @scan_no, @order_mode, "address_success").order("bags.bag_no, orders.order_no")
				b_list = @orders.map{|o| o.bag_list}.uniq
  			@orders = Order.where(bag_list: b_list)
  			if !@orders.blank?
  				is_bag_no = false
  			end
  		end 
		end

		if @orders.blank?
			@err_msg = "该站点无符合模式,未装箱且地址解析成功的包裹信息"
		else
                  if !@orders.where("receiver_province is ? or receiver_city is ? or receiver_district is ?", nil, nil, nil).blank?
                    @err_msg = "有订单省市区为空，请去订单改址页面修改"
                  else
			# 如果是B2B,同一箱的站点应相同
	  	    if @order_mode == "B2B"
		  	if !@site_no.blank?
		  		@orders = @orders.where(site_no: @site_no)
		  	else
		  		@site_no = @orders.first.site_no
		  	end
		    end
		    if @orders.blank?
				@err_msg = "该站点无符合模式,未装箱且地址解析成功的包裹信息"
			else
				if @order_mode == "B2B"
					if is_bag_no
						# 已扫袋子号不包含当前袋子号
						if !@scaned_bags.include?@scan_no
							if @scaned_orders.blank?
								@scaned_orders = @orders.map{|o| o.order_no}.uniq.join(",")
								@scaned_bags = @orders.map{|o| o.bag_list}.uniq.join(",")
							else
								@scaned_orders += ","+ @orders.map{|o| o.order_no}.uniq.join(",")
								@scaned_bags += ","+ @orders.map{|o| o.bag_list}.uniq.join(",")
							end
							@bag_amount += 1
						end
					else
						cur_bags = @orders.map{|o| o.bag_list}.uniq
						# 已扫袋子号不包含当前袋子号
						if !(cur_bags - @scaned_bags.split(",")).blank?
							# 处方号、社保号、电话相同的话取未扫描的第一个袋子
							cur_bag = (cur_bags - @scaned_bags.split(","))[0]
							cur_orders = @orders.where(bag_list: cur_bag)
							if @scaned_orders.blank?
								@scaned_orders = cur_orders.map{|o| o.order_no}.uniq.join(",")
								@scaned_bags = cur_bag
							else
								@scaned_orders += ","+ cur_orders.map{|o| o.order_no}.uniq.join(",")
								@scaned_bags += ","+ cur_bag
							end
							@bag_amount += 1
						end
					end
					# @orders = Order.where(order_no: @scaned_orders.split(","))
					@orders = []
					@scaned_orders.split(",").reverse.each do |o|
						@orders << Order.find_by(order_no: o)
					end						
				elsif @order_mode == "B2C"
					@site_no = @orders.first.site_no
					receiver_phone = @orders.first.receiver_phone
					receiver_addr = @orders.first.receiver_addr
					hospital_name = @orders.first.hospital_name
					# if @site_no.blank?
						# 站点号为空的情况
					# 	@scaned_orders = @orders.map{|o| o.order_no}.uniq.join(",")
					# 	@scaned_bags = @orders.map{|o| o.bag_list}.uniq.join(",")
					# 	@all_scaned = "true"
					# 	@bag_amount += 1
					# 	@to_scan_bags = @orders.map{|o| o.bag_list}.uniq.join(",")
					# else
						# 合单，列出站点号相同或医院名称，收件人电话，收件人地址相同的所有订单
						#@orders = Order.joins(:unit).where("orders.status = ? and units.no = ? and (orders.site_no=? or (orders.receiver_phone = ? and orders.receiver_addr = ? and orders.hospital_name = ?)) and orders.order_mode=? and orders.address_status = ?", "waiting", I18n.t('unit_no.gy'), @site_no, receiver_phone, receiver_addr, hospital_name, @order_mode, "address_success")
					       	@orders = Order.joins(:unit).where("orders.status = ? and units.no = ? and orders.site_no=? and orders.order_mode=? and orders.address_status = ?", "waiting", I18n.t('unit_no.gy'), @site_no, @order_mode, "address_success")

                                                @to_scan_bags = @to_scan_bags.blank? ? @orders.map{|o| o.bag_list}.uniq.join(",") : @to_scan_bags

						if is_bag_no
							if @to_scan_bags.include?@scan_no
								# 已扫袋子号不包含当前袋子号
								if @scaned_bags.blank? || (!@scaned_bags.include?@scan_no)
									if @scaned_orders.blank?
										@scaned_orders = @orders.where(bag_list: @scan_no).map{|o| o.order_no}.join(",")
										@scaned_bags = @scan_no
									else
										@scaned_orders += ","+ @orders.where(bag_list: @scan_no).map{|o| o.order_no}.join(",")
										@scaned_bags += ","+ @scan_no
									end
									@bag_amount += 1

									if !@scaned_bags.blank? && (@scaned_bags.split(",").count == @to_scan_bags.split(",").count)
										@all_scaned = "true"
									end
								end
							else
								@err_msg = "请扫描下方列表中包裹"
								@orders = Order.where(bag_list: @to_scan_bags.split(","))
							end
						else
							cur_bags = @orders.map{|o| o.bag_list}.uniq
							# 已扫袋子号不包含当前袋子号
							if @scaned_bags.blank? || !(cur_bags - @scaned_bags.split(",")).blank?
								# 处方号、社保号、电话相同的话取未扫描的第一个袋子
								cur_bag = (cur_bags - @scaned_bags.split(","))[0]
								if @to_scan_bags.include?cur_bag
									cur_orders = @orders.where(bag_list: cur_bag)
									if @scaned_orders.blank?
										@scaned_orders = cur_orders.map{|o| o.order_no}.uniq.join(",")
										@scaned_bags = cur_bag
									else
										@scaned_orders += ","+ cur_orders.map{|o| o.order_no}.uniq.join(",")
										@scaned_bags += ","+ cur_bag
									end
									@bag_amount += 1
									if !@scaned_bags.blank? && (@scaned_bags.split(",").count == @to_scan_bags.split(',').count)
										@all_scaned = "true"
									end
								else
									@err_msg = "请扫描下方列表中包裹"
									@orders = Order.where(bag_list: @to_scan_bags.split(","))
								end	
							end
						end	
					# end
				end
			
				ods = Order.where("status = ? and updated_at>=? and site_no = ?", "waiting", Date.today, @site_no).where.not(tmp_package: nil)
				if !ods.blank?
					num = ods.map{|o| o.bag_list}.uniq.count
					tmp_package_no = ods.first.tmp_package
					@tmp_save_msg = "站点#{@site_no}暂存箱号#{tmp_package_no}共有#{num}袋"
				end
			end
                  end
		end
	end

	def gy_do_packaged
		@order_bags = params[:order_bags]
  	@err_msg = ""
  	@package_id = params[:package_id]
  	@is_packaged = "0"
  	@scaned_orders = params[:scaned_orders]
  	@scaned_bags = params[:scaned_bags]
  	@order_mode = params[:order_mode]

  	if !@package_id.blank?
  		msg = package_send(Package.find(@package_id))
			@err_msg = msg if !msg.eql?"成功"	
			@is_packaged = "1"
  	else
	  	if !@scaned_orders.blank? && !@scaned_bags.blank?
	  		statuses = Order.where(order_no: @scaned_orders.split(",")).map{|o| o.status}.uniq
	  		if statuses.include?"cancelled"
	  			@err_msg = "此单已拦截"
	  		else
		  		package_no = Package.new_package_no(current_user)
					@package = Package.create package_no: package_no, status: 'waiting', packed_at: Time.now, user_id: current_user.id, order_list: @scaned_orders.split(","), bag_list: @scaned_bags.split(","), unit_id: current_user.unit_id
					@package_id = @package.id
					Order.where(order_no: @scaned_orders.split(",")).update_all package_id: @package.id, status: "packaged", tmp_package: nil
					@is_packaged = "1"
					msg = package_send(@package)
					@err_msg = msg if !msg.eql?"成功"	
				end
			end
		end
	end

	def gy_get_orders(order_bags)
		# “袋子号1*处方号1*顾客电话1：订单号1，订单号2，订单号3|袋子号2*处方号2*顾客电话2：订单号4，订单号5...”
		order_nos = []
		
		order_bags.split("|").each do |o|
			o.split(":")[1].split(",").each do |oo|
				order_nos << oo
			end
		end
		return order_nos
	end

	def gy_get_bags(order_bags)
		# “袋子号1*处方号1*顾客电话1：订单号1，订单号2，订单号3|袋子号2*处方号2*顾客电话2：订单号4，订单号5...”
		bag_nos = []
		
		order_bags.split("|").each do |o|
			bag_nos << o.split(":")[0].split("*")[0]
		end
		return bag_nos
	end

	def send_finish
		packages = []

		if params[:grid] && params[:grid][:selected]
  		selected = params[:grid][:selected]
	       
	    until selected.blank? do 
	      packages = Package.where(id:selected.pop(1000))
	      packages.each do |p|
	      	p.update pkp: "pkp_done" 
	      end
	    end
	    flash[:notice] = "收寄完成"	    
	  else
	  	flash[:alert] = "请勾选收寄完成的箱子"
	  end   
	  
  	respond_to do |format|
      format.html { redirect_to request.referer }
      format.json { head :no_content }
    end
	end

	def tmp_save
		@scaned_orders = params[:scaned_orders]
		site_no = params[:site_no]
		tmp_package_no = ""
		@msg = ""
		
		scaned_orders = Order.where(order_no: @scaned_orders.split(","))
		if !@scaned_orders.blank?
			orders = Order.where("status = ? and updated_at>=? and site_no = ?", "waiting", Date.today, site_no).where.not(tmp_package: nil)

			#orders = Order.where("status = ? and updated_at>=? and receiver_addr = ? and receiver_phone = ? and hospital_name = ?", "waiting", Date.today, scaned_orders.first.receiver_addr, scaned_orders.first.receiver_phone, scaned_orders.first.hospital_name ).where.not(tmp_package: nil)
	
			ActiveRecord::Base.transaction do
				begin
					if !orders.blank?
						tmp_package_no = orders.first.tmp_package
					else
						tmp_package_no = get_new_tmp_package_no
					end
					Order.where(order_no: @scaned_orders.split(",")).update_all tmp_package: tmp_package_no, updated_at: Time.now

					@msg = "该袋子已暂存至箱子#{tmp_package_no}"
				rescue Exception => e
          flash[:alert] = e.message 
          raise ActiveRecord::Rollback
        end
      end
		end
	end

	def get_new_tmp_package_no
		order =  Order.where("status = ? and updated_at>=?", "waiting", Date.today).where.not(tmp_package: nil).order(:tmp_package).last

 		new_tmp_package_no = order.blank? ? (Date.today.day.to_s + "_"+"1".rjust(3, '0')) : (Date.today.day.to_s + "_"+((order.tmp_package.split("_")[1].to_i) +1).to_s.rjust(3, '0'))
	end

	
	private

	def package_params
    params[:package].permit(:package_no, :express_no, :route_code, :status, :packed_at, :user_id, :order_list, :bag_list)
  end

end
