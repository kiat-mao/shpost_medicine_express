class PackagesController < ApplicationController
  load_and_authorize_resource :package
  protect_from_forgery :except => [:tkzd,:zxqd]

  # GET /packages
  # GET /packages.json
  def index
  	@selected = nil
  	@no = params[:no]

  	# 根据处方号/社保号/收件人电话查询
    @packages = Package.accessible_by(current_ability)
		if !@no.blank?
	  	@packages = Package.accessible_by(current_ability).joins(:orders).where("orders.prescription_no = ? or orders.social_no = ? or orders.receiver_phone = ?", @no, @no, @no)	
		end

		# 显示保价订单
	  if !params[:selected].blank? && (params[:selected].eql?"true")
      @packages = @packages.where("valuation_sum>0")
      @selected = params[:selected]
    end
    
    @packages_grid = initialize_grid(@packages,
    	:order => 'packed_at',
      :order_direction => 'asc', 
      :per_page => params[:page_size],
  		:name => 'packages',
  		:enable_export_to_csv => true,
    	:csv_file_name => 'packages',
    	:csv_encoding => 'gbk')
    	export_grid_if_requested
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

		if params[:packages] && params[:packages][:selected]
  		selected = params[:packages][:selected]
	       
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
		if (current_user.unit.no == I18n.t('unit_no.gy'))
			if @package.pkp.eql?"pkp_done"
				@package.cancelled
			end
		else
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
			if Bag.where(bag_no: @bag_no, belong_package_id: nil).blank? || !Bag.joins(:belong_package).where("bags.bag_no=? and packages.packed_at>=? and packages.packed_at<?", @bag_no, Time.now-1.year, Time.now).blank?
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
  	@unboxing = ""
  	
  	if !@package_id.blank?
  		package = Package.find(@package_id)
  		if !package.blank?
  			if !package.has_boxing && package.express_no.blank?
		  		msg = package_send(package)
					@err_msg = msg if !msg.eql?"成功"	
				end
				@is_packaged = "1"
			end
  	else
	  	if !@order_bags.blank?
		  	uneql_order_no = uneql_order_no(@order_bags)
		  	if !uneql_order_no.blank?
		  		@err_msg = "订单号#{uneql_order_no}，有袋子未扫描"
		  	else
		  		order_list = get_orders(@order_bags)
		  		bag_list = get_bags(@order_bags)
	  			package_no = Package.new_package_no(current_user)
	  			ActiveRecord::Base.transaction do
		  			begin
		  				@package = Package.create! package_no: package_no, status: 'waiting', packed_at: Time.now, user_id: current_user.id, order_list: order_list, bag_list: bag_list, unit_id: current_user.unit_id, valuation_sum: Order.where(order_no: order_list).sum(:valuation_amount)
							@package_id = @package.id
							Bag.where(bag_no: bag_list).update_all belong_package_id: @package_id
							Order.where(order_no: order_list).each do |o|
								if o.package_list.blank?
									o.update package_list: package_no
								else
									if !(o.package_list.include?package_no)
										plist = o.package_list + "," + package_no
										o.update package_list: plist
									end
								end

								if o.bags.where.not(belong_package_id: nil).count == o.bags.count
									o.update status: "packaged"
								end
							end
							commodity_list = get_commodities(@package)
							@package.update commodity_list: commodity_list
							
							@is_packaged = "1"
						rescue Exception => e
		          flash[:alert] = e.message 
		          raise ActiveRecord::Rollback
		        end
		      end		
	        if !@package.has_boxing
						msg = package_send(@package)
						@err_msg = msg if !msg.eql?"成功"	
						@unboxing = "true"	
					else
						@unboxing = "false"
					end
				end
			end		
		end
	end

	def uneql_order_no(order_bags)
		# “订单号1：袋子号1，袋子号2，袋子号3|订单号2：袋子号4，袋子号5...”
		uneql_order_no = ""
		order_bags_arr = order_bags.split("|")
		order_bags_arr.each do |o|
			obarr = o.split(":")
			order = Order.find_by(order_no: obarr[0])
			# 不可拆箱为true，且袋子数量未扫完，需要弹框提醒
			if order.unboxing && (order.bags.count > obarr[1].split(",").count)
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

	def get_commodities(package)
		commodity_list = []

		oids = Bag.where(belong_package_id: package.id).map{|b| b.order_id}.compact

		Order.where(id: oids).each do |o|
			if !o.commodities.blank?
				commodity_list += o.commodities.map{|c| c.commodity_no}.compact.uniq 
			end
		end

		return commodity_list
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
		begin
			interface_sender = XydInterfaceSender.order_create_interface_sender_initialize(package)
			interface_sender.interface_send(10)
			msg = XydInterfaceSender.get_response_message(interface_sender)
			# package.update express_no: "e000001", route_code: "r000001"
			# msg = "成功"
		rescue Exception => e
      msg = e.message
    end
		return msg			
	end


	def package_send_by_waybill_no(package)
		interface_sender = XydInterfaceSender.order_create_by_waybill_no_interface_sender_initialize(package)
		interface_sender.interface_send(10)
		msg = XydInterfaceSender.get_response_message(interface_sender)
		# package.update express_no: "e000001", route_code: "r000001"
		# msg = "成功"
		return msg			
	end


  def gy_scan
  	@package_no = Package.get_package_no_by_user(current_user)
  	@bag_amount = 0
  	@orde_mode = ""
  end

 #  def gy_find_bag_result
 #  	@scan_no = params[:scan_no]
 #  	@site_no = params[:site_no]
 #  	@err_msg = ""
 #  	@bag_amount = params[:bag_amount].to_i
 #  	@order_mode = params[:order_mode]
 #  	@orders =nil
 #  	@to_scan_bags = params[:to_scan_bags]
 #  	@scaned_orders = params[:scaned_orders]
 #  	@scaned_bags = params[:scaned_bags]
 #  	@all_scaned = "false"
 #  	is_bag_no = nil
 #  	@tmp_save_msg = ""

 #  	# 同一箱模式应相同，即都为B2B或都为B2C
 #  	# 扫第一个，order_mode为空
 #  	if @order_mode.blank?
 #  		# 用袋子号查
 #  		@orders = Order.joins("left outer join bags on orders.bag_list like bags.bag_no").joins(:unit).where("units.no = ? and bags.bag_no = ?", I18n.t('unit_no.gy'), @scan_no).order("bags.bag_no, orders.order_no")
 #  		if !@orders.blank?
 #  			@order_mode = @orders.first.order_mode
 #  			is_bag_no = true  			
 #  		else
 #  			# 用处方号，社保号，收件人电话查
 #  			@orders = Order.joins("left outer join bags on orders.bag_list like bags.bag_no").joins(:unit).where("units.no = ? and (orders.prescription_no = ? or orders.social_no = ? or orders.receiver_phone = ?)", I18n.t('unit_no.gy'), @scan_no, @scan_no, @scan_no)
 #  			b_list = @orders.map{|o| o.bag_list}.uniq
 #  			@orders = Order.where(bag_list: b_list).order("orders.created_at desc")
 #  			if !@orders.blank?
 #  				@order_mode = @orders.first.order_mode
 #  				is_bag_no = false
 #  			end
 #  		end 		
 #  	else
 #  		# order_mode不为空
 #  		@orders = Order.joins("left outer join bags on orders.bag_list like bags.bag_no").joins(:unit).where("units.no = ? and bags.bag_no = ? and orders.order_mode = ?", I18n.t('unit_no.gy'), @scan_no, @order_mode).order("bags.bag_no, orders.order_no")
 #  		if !@orders.blank?
 #  			is_bag_no = true  			
	# 		else
	# 			@orders = Order.joins("left outer join bags on orders.bag_list like bags.bag_no").joins(:unit).where("units.no = ? and (orders.prescription_no = ? or orders.social_no = ? or orders.receiver_phone = ?) and orders.order_mode = ?", I18n.t('unit_no.gy'), @scan_no, @scan_no, @scan_no, @order_mode)
	# 			b_list = @orders.map{|o| o.bag_list}.uniq
 #  			@orders = Order.where(bag_list: b_list).order("orders.created_at desc")
 #  			if !@orders.blank?
 #  				is_bag_no = false
 #  			end
 #  		end 
	# 	end

	# 	if @orders.blank?
	# 		@err_msg = "无邮件信息"
	# 	else
	# 		@orders = @orders.where(status: "waiting")
	# 		if @orders.blank?
	# 			@err_msg = "重复装箱"
	# 		else
	# 			@orders = @orders.where(address_status: "address_success")
	# 			if @orders.blank?
	# 				@err_msg = "地址解析不成功"
	# 			else
	# 			  if !@orders.where("receiver_province is ? or receiver_city is ? or receiver_district is ?", nil, nil, nil).blank?
	# 	        @err_msg = "有订单省市区为空，请去订单改址页面修改"
	# 	      else
	# 					# 如果是B2B,同一箱的站点应相同
	# 			    if @order_mode == "B2B"
	# 				  	if !@site_no.blank?
	# 				  		@orders = @orders.where(site_no: @site_no)
	# 				  	else
	# 				  		@site_no = @orders.first.site_no
	# 				  	end
	# 			    end
	# 			    if @orders.blank?
	# 						@err_msg = "非同一站点"
	# 					else
	# 						if @order_mode == "B2B"
	# 							if is_bag_no
	# 								# 已扫袋子号不包含当前袋子号
	# 								if !@scaned_bags.include?@scan_no
	# 									if @scaned_orders.blank?
	# 										@scaned_orders = @orders.map{|o| o.order_no}.uniq.join(",")
	# 										@scaned_bags = @orders.map{|o| o.bag_list}.uniq.join(",")
	# 									else
	# 										@scaned_orders += ","+ @orders.map{|o| o.order_no}.uniq.join(",")
	# 										@scaned_bags += ","+ @orders.map{|o| o.bag_list}.uniq.join(",")
	# 									end
	# 									@bag_amount += 1
	# 								end
	# 							else
	# 								cur_bags = @orders.map{|o| o.bag_list}.uniq
	# 								# 已扫袋子号不包含当前袋子号
	# 								if !(cur_bags - @scaned_bags.split(",")).blank?
	# 									# 处方号、社保号、电话相同的话取未扫描的第一个袋子
	# 									cur_bag = (cur_bags - @scaned_bags.split(","))[0]
	# 									cur_orders = @orders.where(bag_list: cur_bag)
	# 									if @scaned_orders.blank?
	# 										@scaned_orders = cur_orders.map{|o| o.order_no}.uniq.join(",")
	# 										@scaned_bags = cur_bag
	# 									else
	# 										@scaned_orders += ","+ cur_orders.map{|o| o.order_no}.uniq.join(",")
	# 										@scaned_bags += ","+ cur_bag
	# 									end
	# 									@bag_amount += 1
	# 								end
	# 							end
								
	# 							@orders = []
	# 							@scaned_orders.split(",").reverse.each do |o|
	# 								@orders << Order.find_by(order_no: o)
	# 							end		
	# 							waiting_orders = Order.joins(:unit).where(units: {no:I18n.t('unit_no.gy')}, site_no: @site_no, order_mode: @order_mode, address_status: "address_success", status: "waiting").where("orders.created_at >= ? and orders.created_at < ?", Date.yesterday, Date.tomorrow).where.not(order_no: @scaned_orders.split(","))	
	# 							waiting_orders.each do |w|
	# 								@orders << w
	# 							end
	# 						elsif @order_mode == "B2C"
	# 							@site_no = @orders.first.site_no
	# 							receiver_phone = @orders.first.receiver_phone
	# 							receiver_addr = @orders.first.receiver_addr
	# 							hospital_name = @orders.first.hospital_name
	# 							# if @site_no.blank?
	# 								# 站点号为空的情况
	# 							# 	@scaned_orders = @orders.map{|o| o.order_no}.uniq.join(",")
	# 							# 	@scaned_bags = @orders.map{|o| o.bag_list}.uniq.join(",")
	# 							# 	@all_scaned = "true"
	# 							# 	@bag_amount += 1
	# 							# 	@to_scan_bags = @orders.map{|o| o.bag_list}.uniq.join(",")
	# 							# else
	# 								# 合单，列出站点号相同或医院名称，收件人电话，收件人地址相同的所有订单
	# 								#@orders = Order.joins(:unit).where("orders.status = ? and units.no = ? and (orders.site_no=? or (orders.receiver_phone = ? and orders.receiver_addr = ? and orders.hospital_name = ?)) and orders.order_mode=? and orders.address_status = ?", "waiting", I18n.t('unit_no.gy'), @site_no, receiver_phone, receiver_addr, hospital_name, @order_mode, "address_success")
	# 					       	@orders = Order.joins(:unit).where(units: {no:I18n.t('unit_no.gy')}, status: "waiting", site_no: @site_no, order_mode: @order_mode, address_status: "address_success")

	# 	                @to_scan_bags = @to_scan_bags.blank? ? @orders.map{|o| o.bag_list}.uniq.join(",") : @to_scan_bags

	# 								if is_bag_no
	# 									if @to_scan_bags.include?@scan_no
	# 										# 已扫袋子号不包含当前袋子号
	# 										if @scaned_bags.blank? || (!@scaned_bags.include?@scan_no)
	# 											if @scaned_orders.blank?
	# 												@scaned_orders = @orders.where(bag_list: @scan_no).map{|o| o.order_no}.join(",")
	# 												@scaned_bags = @scan_no
	# 											else
	# 												@scaned_orders += ","+ @orders.where(bag_list: @scan_no).map{|o| o.order_no}.join(",")
	# 												@scaned_bags += ","+ @scan_no
	# 											end
	# 											@bag_amount += 1

	# 											if !@scaned_bags.blank? && (@scaned_bags.split(",").count == @to_scan_bags.split(",").count)
	# 												@all_scaned = "true"
	# 											end
	# 										end
	# 									else
	# 										@err_msg = "请扫描下方列表中包裹"
	# 										@orders = Order.where(bag_list: @to_scan_bags.split(","))
	# 									end
	# 								else
	# 									cur_bags = @orders.map{|o| o.bag_list}.uniq
	# 									# 已扫袋子号不包含当前袋子号
	# 									if @scaned_bags.blank? || !(cur_bags - @scaned_bags.split(",")).blank?
	# 										# 处方号、社保号、电话相同的话取未扫描的第一个袋子
	# 										cur_bag = (cur_bags - @scaned_bags.split(","))[0]
	# 										if @to_scan_bags.include?cur_bag
	# 											cur_orders = @orders.where(bag_list: cur_bag)
	# 											if @scaned_orders.blank?
	# 												@scaned_orders = cur_orders.map{|o| o.order_no}.uniq.join(",")
	# 												@scaned_bags = cur_bag
	# 											else
	# 												@scaned_orders += ","+ cur_orders.map{|o| o.order_no}.uniq.join(",")
	# 												@scaned_bags += ","+ cur_bag
	# 											end
	# 											@bag_amount += 1
	# 											if !@scaned_bags.blank? && (@scaned_bags.split(",").count == @to_scan_bags.split(',').count)
	# 												@all_scaned = "true"
	# 											end
	# 										else
	# 											@err_msg = "请扫描下方列表中包裹"
	# 											@orders = Order.where(bag_list: @to_scan_bags.split(","))
	# 										end	
	# 									end
	# 								end	
	# 							# end
	# 						end
						
	# 						ods = Order.where("status = ? and updated_at>=? and site_no = ?", "waiting", Date.today, @site_no).where.not(tmp_package: nil)
	# 						if !ods.blank?
	# 							num = ods.map{|o| o.bag_list}.uniq.count
	# 							tmp_package_no = ods.first.tmp_package
	# 							@tmp_save_msg = "站点#{@site_no}暂存箱号#{tmp_package_no}共有#{num}袋"
	# 						end
	# 					end
	# 	      end
	# 	    end
	#     end
	# 	end
	# end

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
  	cur_bag = ""
  	cur_orders = ""
  	@bj_msg = ""  #保价提示
  	
  	unit_id = Unit.find_by(no: I18n.t('unit_no.gy')).id
  	# 用袋子号查
		@orders = Order.joins("left outer join bags on orders.bag_list like bags.bag_no").where(unit_id: unit_id, bags: {bag_no: @scan_no}).order("bags.bag_no, orders.order_no")
		# 同一箱模式应相同，即都为B2B或都为B2C
		if @order_mode.blank?
			@order_mode = @orders.first.try :order_mode
		else
			@orders = @orders.map{|o| (o.order_mode==@order_mode) ? o : nil}.compact
		end
		if !@orders.blank?
			is_bag_no = true  			
		else
			# 用处方号，收件人电话, 社保号查
			@orders = Order.where("unit_id = ? and (orders.prescription_no = ? or orders.receiver_phone = ? or orders.social_no = ?)", unit_id, @scan_no, @scan_no, @scan_no)
			b_list = @orders.map{|o| o.bag_list}.uniq
			@orders = Order.where(bag_list: b_list).order("orders.created_at desc")
			if @order_mode.blank?
				@order_mode = @orders.first.try :order_mode
			else
				@orders = @orders.map{|o| (o.order_mode==@order_mode) ? o : nil}.compact
			end
			is_bag_no = false if !@orders.blank?
		end 	

		if @orders.blank?
			@err_msg = "无邮件信息"
			return
		end
		
		if !@orders.map{|o| (o.status=="cancelled") ? o : nil}.compact.blank?
			@err_msg = "已拦截"
			return
		end

		@orders = @orders.map{|o| (o.status=="waiting") ? o : nil}.compact
		if @orders.blank?
			@err_msg = "重复装箱"
			return
		end
			
		@orders = @orders.map{|o| (o.address_status=="address_success") ? o : nil}.compact
		if @orders.blank?
			@err_msg = "地址解析不成功"
			return
		end
		
		if !@orders.map{|o| (o.receiver_province.blank? || o.receiver_city.blank? || o.receiver_district.blank?) ? o : nil}.compact.blank?
      @err_msg = "有订单省市区为空，请去订单改址页面修改"
      return
    end

    if !@orders.map{|o| (!(o.receiver_province.start_with?'上海') && !o.no_modify) ? o : nil}.compact.blank?
      @err_msg = "外省邮件，地址未确认"
      return
    end
		      
		# 如果是B2B,同一箱的站点应相同
    if @order_mode == "B2B"
	  	if !@site_no.blank?
	  		@orders = @orders.map{|o| (o.site_no==@site_no) ? o : nil}.compact
	  	else
	  		@site_no = @orders.first.site_no
	  	end
    end
    if @orders.blank?
			@err_msg = "非同一站点"
			return
		end
						
		if @order_mode == "B2B"
			if is_bag_no
				if !@scaned_bags.include?@scan_no
					cur_bag = @scan_no
					cur_orders = @orders.map{|o| o.order_no}.uniq.join(",")
				end
			else
				cur_bags = @orders.map{|o| o.bag_list}.uniq
				# 已扫袋子号不包含当前袋子号
				if !(cur_bags - @scaned_bags.split(",")).blank?
					# 处方号、社保号、电话相同的话取未扫描的第一个袋子
					cur_bag = (cur_bags - @scaned_bags.split(","))[0]
					cur_orders = @orders.map{|o| (o.bag_list==cur_bag) ? o.order_no : nil}.compact.uniq.join(",")
				end
			end
			# B2B每次扫描是保价订单,弹框提示
			os = @orders.map{|o| (cur_orders.split(",").include?o.order_no) ? o : nil}.compact.uniq
			vos = os.map{|o| (!o.valuation_amount.blank? && o.valuation_amount > 0) ? o : nil}.compact.uniq
			@bj_msg = "有保价订单!" if !vos.blank?

			# 组装@scaned_orders, @scaned_bags, 已扫袋数+1
			scan_result = get_scaned_orders_bags(@scaned_orders, @scaned_bags, cur_bag, cur_orders, @bag_amount, @to_scan_bags)
			@scaned_orders = scan_result[0]
			
			@orders = Order.where(order_no: @scaned_orders.split(",").reverse)	
			waiting_orders = Order.where(unit_id:unit_id, site_no: @site_no, order_mode: @order_mode, address_status: "address_success", status: "waiting").where("orders.created_at >= ? and orders.created_at < ?", Date.yesterday, Date.tomorrow).where.not(order_no: @scaned_orders.split(","), receiver_province: nil, receiver_city: nil, receiver_district: nil)

			@orders = @orders.map{|o| o} + waiting_orders.map{|w| w}
		elsif @order_mode == "B2C"
			@site_no = @orders.first.site_no
			
     	@orders = Order.where(unit_id: unit_id, status: "waiting", site_no: @site_no, order_mode: @order_mode, address_status: "address_success").where.not(receiver_province: nil, receiver_city: nil, receiver_district: nil)

      @to_scan_bags = @to_scan_bags.blank? ? @orders.map{|o| o.bag_list}.uniq.join(",") : @to_scan_bags

      # B2C合并站点后所有订单中有保价订单,首次扫描时弹框提示
      if @scaned_bags.blank?
				vos = @orders.map{|o| (!o.valuation_amount.blank? && o.valuation_amount > 0) ? o : nil}.compact.uniq
				@bj_msg = "当前箱有保价订单!" if !vos.blank?
			end

			if is_bag_no
				if @to_scan_bags.include?@scan_no
					if @scaned_bags.blank? || (!@scaned_bags.include?@scan_no)
						cur_bag = @scan_no
						cur_orders = @orders.map{|o| (o.bag_list==@scan_no) ? o.order_no : nil}.compact.uniq.join(",")						
					end
				else
					@err_msg = "请扫描下方列表中包裹"
				end
			else
				cur_bags = @orders.map{|o| o.bag_list}.uniq
				# 已扫袋子号不包含当前袋子号
				if @scaned_bags.blank? || !(cur_bags - @scaned_bags.split(",")).blank?
					# 处方号、社保号、电话相同的话取未扫描的第一个袋子
					cur_bag = (cur_bags - @scaned_bags.split(","))[0]
					if @to_scan_bags.include?cur_bag
						cur_orders = @orders.map{|o| (o.bag_list==cur_bag) ? o.order_no : nil}.compact.uniq.join(",")
					else
						@err_msg = "请扫描下方列表中包裹"
					end	
				end
			end	
			# 组装@scaned_orders, @scaned_bags, 已扫袋数+1, B2C判是否已全扫完
			scan_result = get_scaned_orders_bags(@scaned_orders, @scaned_bags, cur_bag, cur_orders, @bag_amount, @to_scan_bags)
			@scaned_orders = scan_result[0]
		end
		
		@scaned_bags = scan_result[1]
		@bag_amount = scan_result[2]
		@all_scaned = scan_result[3]
		# 判是否有暂存袋子				
		ods = @orders.map{|o| ((o.updated_at>=Date.today) && (!o.tmp_package.blank?)) ? o : nil}.compact
		if !ods.blank?
			num = ods.map{|o| o.bag_list}.uniq.count
			tmp_package_no = ods.first.tmp_package
			@tmp_save_msg = "站点#{@site_no}暂存箱号#{tmp_package_no}共有#{num}袋"
		end
	end

	def get_scaned_orders_bags(scaned_orders, scaned_bags, cur_bag, cur_orders, bag_amount, to_scan_bags)
		all_scaned = "false"

		if scaned_orders.blank?
			scaned_orders = cur_orders
			scaned_bags = cur_bag
		else
			scaned_orders += ","+ cur_orders
			scaned_bags += ","+ cur_bag
		end
		bag_amount += 1

		# B2C判是否已全扫完
		if !to_scan_bags.blank? && !scaned_bags.blank? && (scaned_bags.split(",").count == to_scan_bags.split(',').count)
			all_scaned = "true"
		end

		return [scaned_orders, scaned_bags, bag_amount, all_scaned]
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
  		@package = Package.find(@package_id)
  		if !@package.blank? && @package.express_no.blank?
	  		msg = package_send(@package)
				@err_msg = msg if !msg.eql?"成功"	
				@is_packaged = "1"
			end
  	else
	  	if !@scaned_orders.blank? && !@scaned_bags.blank?
	  		statuses = Order.where(order_no: @scaned_orders.split(",")).map{|o| o.status}.uniq
	  		if statuses.include?"cancelled"
	  			@err_msg = "此单已拦截"
	  		else
		  		package_no = Package.new_package_no(current_user)
		  		ActiveRecord::Base.transaction do
		  			begin
							@package = Package.create! package_no: package_no, status: 'waiting', packed_at: Time.now, user_id: current_user.id, order_list: @scaned_orders.split(","), bag_list: @scaned_bags.split(","), unit_id: current_user.unit_id, valuation_sum: Order.where(order_no: @scaned_orders.split(",")).sum(:valuation_amount)
							@package_id = @package.id
							Order.where(order_no: @scaned_orders.split(",")).update_all package_id: @package.id, status: "packaged", tmp_package: nil
							
							@is_packaged = "1"
						rescue Exception => e
		          flash[:alert] = e.message 
		          raise ActiveRecord::Rollback
		        end
      		end	
      		if !@package_id.blank?
	      		msg = package_send(@package)
						@err_msg = msg if !msg.eql?"成功"
					end
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

	def package_report
  	@create_at_start = !params[:create_at_start].blank? ? params[:create_at_start] : nil
    @create_at_end = !params[:create_at_end].blank? ? params[:create_at_end] : nil
    @results = nil

    unless request.get?
      if @create_at_start.blank? && @create_at_end.blank?
      	flash[:alert] = "请选择装箱日期"
        redirect_to request.referer
      else
      	@results = init_result(@create_at_start, @create_at_end)
	    end
    end
  end

  def init_result(create_at_start, create_at_end)
  	results = {}
  	package_hj = 0
  	bag_hj = 0
  	hd_hj = 0
  	
  	unit_id = Unit.find_by(no: I18n.t('unit_no.gy')).id
    
    where_sql = "orders.unit_id = #{unit_id} and orders.status = 'packaged'"
    if !create_at_start.blank?
      where_sql += " and packed_at >= '#{create_at_start.to_date}'"
    end
    if !create_at_end.blank?
      where_sql += " and packed_at < '#{create_at_end.to_date+1.days}'"
    end

    orders = Order.joins(:package).where(where_sql)

    hospitals = orders.group(:hospital_name).count.map{|k,v| k}.compact.uniq
    hospitals.each do |h|
    	package_amount = orders.map{|o| (o.hospital_name == h) ? o.package_id : nil}.compact.uniq.count
    	package_hj += package_amount
    	bag_amount = orders.map{|o| (o.hospital_name == h) ? o.bag_list : nil}.compact.uniq.count
    	bag_hj += bag_amount
    	# 合单箱数,同一站点号袋子数量大于1的即为有合单,合单箱数记1,以此类推
    	bag_site = Bag.left_joins(:order).joins(:package).where(where_sql).where("orders.hospital_name= ?", h).group("orders.site_no, bags.bag_no").select("orders.site_no, bags.bag_no")
			hd_amount = Bag.select("site_no").from("(#{bag_site.to_sql}) bag_site").group("site_no").having("count(*) > 1").count.count

    	# o=orders.where("orders.hospital_name= ?", h).group(:site_no,:bag_list).select(:site_no,:bag_list)
    	# hd_amount = Order.select("*").from("(#{o.to_sql}) as bag_site").group("site_no").having("count(*) > 1").count.count

    	hd_hj += hd_amount

    	results[h] = [package_amount, bag_amount, hd_amount]
    end
    results["合计"] = [package_hj, bag_hj, hd_hj]
    results["合计单量"] = [orders.where.not(hospital_name: nil).group(:package_id).count.size, ""]
    return results
  end

  def package_report_export
  	@create_at_start = !params[:create_at_start].blank? ? params[:create_at_start] : nil
  	@create_at_end = !params[:create_at_end].blank? ? params[:create_at_end] : nil

  	if @create_at_start.blank? && @create_at_end.blank?
    	flash[:alert] = "请先查询"
      redirect_to request.referer
    else
  		@results = init_result(@create_at_start, @create_at_end)

	  	if @results.blank?
	      flash[:alert] = "无数据"
	      redirect_to request.referer
	    else
	    	send_data(report_xls_content_for(@create_at_start, @create_at_end, @results),:type => "text/excel;charset=utf-8; header=present",:filename => "报表_#{Time.now.strftime("%Y%m%d")}.xls")  
	    end
	  end
  end

  def report_xls_content_for(create_at_start, create_at_end, results) 
    xls_report = StringIO.new  
    book = Spreadsheet::Workbook.new  
    sheet1 = book.create_worksheet :name => "报表"  
    
    title = Spreadsheet::Format.new :weight => :bold, :size => 14
    filter = Spreadsheet::Format.new :size => 12
    body = Spreadsheet::Format.new :size => 13, :border => :thin, :align => :center
    
    sheet1.row(0).default_format = filter
    sheet1[0,0] = "装箱日期：#{create_at_start}至#{create_at_end}"

    sheet1.row(2).default_format = title
    sheet1.row(2).concat %w{所属医院名称 装箱数量 装箱袋数 合单箱数}
    
    count_row = 3
    
    results.each do |k, v|
      sheet1[count_row,0] = k
      sheet1[count_row,1] = v[0]
      sheet1[count_row,2] = v[1]
      sheet1[count_row,3] = v[2]

      0.upto(3) do |x|
        sheet1.row(count_row).set_format(x, body)
      end 

      count_row += 1
    end

    book.write xls_report  
    xls_report.string
  end

  

  def to_date(time)
    date = Date.civil(time.split(/-|\//)[0].to_i,time.split(/-|\//)[1].to_i,time.split(/-|\//)[2].to_i)
    return date
  end

  def sorting_code_report
  	@create_at_start = !params[:create_at_start].blank? ? params[:create_at_start] : nil
    @create_at_end = !params[:create_at_end].blank? ? params[:create_at_end] : nil
    @results = nil

    unless request.get?
      if @create_at_start.blank? && @create_at_end.blank?
      	flash[:alert] = "请选择日期"
        redirect_to request.referer
      else
      	@results = sorting_code_init_result(@create_at_start, @create_at_end)
	    end
    end
  end

  def sorting_code_init_result(create_at_start, create_at_end)
  	results = {}
  	
  	unit_id = Unit.find_by(no: I18n.t('unit_no.gy')).id
    
    where_sql = "packages.unit_id = #{unit_id}"
    if !create_at_start.blank?
      where_sql += " and packed_at >= '#{create_at_start.to_date}'"
    end
    if !create_at_end.blank?
      where_sql += " and packed_at < '#{create_at_end.to_date+1.days}'"
    end

    results = Package.where(where_sql).group(:sorting_code).count
    results["合计"] = Package.where(where_sql).count
    
    return results
  end

  def sorting_code_report_export
  	@create_at_start = !params[:create_at_start].blank? ? params[:create_at_start] : nil
  	@create_at_end = !params[:create_at_end].blank? ? params[:create_at_end] : nil

  	if @create_at_start.blank? && @create_at_end.blank?
    	flash[:alert] = "请先查询"
      redirect_to request.referer
    else
  		@results = sorting_code_init_result(@create_at_start, @create_at_end)

	  	if @results.blank?
	      flash[:alert] = "无数据"
	      redirect_to request.referer
	    else
	    	send_data(sorting_code_report_xls_content_for(@create_at_start, @create_at_end, @results),:type => "text/excel;charset=utf-8; header=present",:filename => "同城分拣码统计表_#{Time.now.strftime("%Y%m%d")}.xls")  
	    end
	  end
  end

  def sorting_code_report_xls_content_for(create_at_start, create_at_end, results) 
    xls_report = StringIO.new  
    book = Spreadsheet::Workbook.new  
    sheet1 = book.create_worksheet :name => "报表"  
    
    filter = Spreadsheet::Format.new :size => 12
    body = Spreadsheet::Format.new :size => 13, :border => :thin, :align => :center
    
    sheet1.row(0).default_format = filter
    sheet1[0,0] = "日期：#{create_at_start}至#{create_at_end}"

    sheet1.row(2).concat %w{同城分拣码 邮件数量}
    0.upto(1) do |x|
      sheet1.row(2).set_format(x, body)
    end 
    
    count_row = 3
    
    results.each do |k, v|
      sheet1[count_row,0] = k
      sheet1[count_row,1] = v

      0.upto(1) do |x|
        sheet1.row(count_row).set_format(x, body)
      end 

      count_row += 1
    end

    book.write xls_report  
    xls_report.string
  end
	
	# def scan_express_no
	# 	package_id =params[:package_id]
	# 	scan_express_no = params[:scan_express_no]

	# 	if !package_id.blank? && !scan_express_no.blank?
	# 		package = Package.find(package_id)
	# 		if !package.blank? && package.has_boxing
	# 			package.update express_no: scan_express_no
	# 			msg = package_send_by_waybill_no(package)		
	# 			flash[:notice] = "面单号绑定成功"
	# 		end
	# 	end
		
	# 	redirect_to request.referer
	# end
	def scan_express_no
		package_id =params[:package_id]
		scan_express_no = params[:scan_express_no]

		if !package_id.blank? && !scan_express_no.blank?
			if !current_user.kdbg_printer.blank? && !(["8","9"].include?scan_express_no[0])
				@err_msg = "请输入快递包裹面单号"
				return
			end
			if !current_user.ems_printer.blank? && !(scan_express_no[0].eql?"1")
				@err_msg = "请输入国内特快专递面单号"
				return
			end

			package = Package.find(package_id)
			if !package.blank? && package.has_boxing
				package.update express_no: scan_express_no
				msg = package_send_by_waybill_no(package)	
				flash[:notice] = "面单号绑定成功"	
			end
			redirect_to request.referer
		end	
	end

	private

	def package_params
    params[:package].permit(:package_no, :express_no, :route_code, :status, :packed_at, :user_id, :order_list, :bag_list)
  end

end
