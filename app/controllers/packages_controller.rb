class PackagesController < ApplicationController
  load_and_authorize_resource :package
  protect_from_forgery :except => [:tkzd,:zxqd]

  # GET /packages
  # GET /packages.json
  def index
  	@packages = Package.accessible_by(current_ability)
  	if params[:grid].blank?
	  	@packages = @packages.where(packed_at: Date.today)
	  end
    @packages_grid = initialize_grid(@packages,
         :order => 'packed_at',
         :order_direction => 'desc', 
         :per_page => params[:page_size])
  end

  def tkzd
  	@result = []

  	if !params[:package_id].blank?
  		@result << Package.find(params[:package_id])
  	else
	  	if params[:grid] && params[:grid][:selected]
	      selected = params[:grid][:selected]
	       
	      until selected.blank? do 
	        @result += Package.where(id:selected.pop(1000))
	      end
	  	else
	      flash[:alert] = "请勾选需要打印的箱子"
	      respond_to do |format|
	        format.html { redirect_to packages_url }
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
  		if params[:grid] && params[:grid][:selected]
	      selected = params[:grid][:selected]
	       
	      until selected.blank? do 
	        @result += Package.where(id:selected.pop(1000))
	      end
	  	else
	      flash[:alert] = "请勾选需要打印的箱子"
	      respond_to do |format|
	        format.html { redirect_to packages_url }
	        format.json { head :no_content }
	      end
	    end
  	end
	end

	def send_sy
		@result = []

  	selected = params[:grid][:selected]
	       
    until selected.blank? do 
      @result += Package.where(id:selected.pop(1000))
    end
	  
    respond_to do |format|
      format.html { redirect_to packages_url }
      format.json { head :no_content }
    end
	end

	def canceled
		if ["waiting", "failed"].include?@package.status
			@package.orders.update_all status: "waiting", package_id: nil
			@package.update status: "cancelled"
		end

		respond_to do |format|
			flash[:message] = "箱子已作废"
      format.html { redirect_to request.referer }
      format.json { head :no_content }
    end
	end

  def scan
  	@package_no = Package.get_package_no_by_user(current_user)
  end

  def find_bag_result
  	@bag_no = params[:bag_no]
  	@site_no = params[:site_no]
  	@order_bags = params[:order_bags]
  	@err_msg = ""
  	
# binding.pry  	
  	bag = Bag.find_by(bag_no: @bag_no)
		if bag.blank?
			@err_msg = "包裹无信息"
		else
			# if (bag.order.status.eql?"packaged")
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
	  			# binding.pry
  			end
  		end
  	end
		
    # respond_to do |format|
    #   format.js 
    # end
	end

	def do_packaged
		@order_bags = params[:order_bags]
  	@err_msg = ""
  	@package_id = params[:package_id]
  	@is_packaged = "0"
  	@result = {}

  	if !@package_id.blank?
  		@result = package_send(Package.find(@package_id))
			@err_msg = @result["err_msg"] if !@result["err_msg"].blank?	
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
					package = Package.create package_no: package_no, status: 'waiting', packed_at: Time.now, user_id: current_user.id, order_list: order_list, bag_list: bag_list
					@package_id = package.id
					Order.where(order_no: order_list).update_all package_id: package.id, status: "packaged"
					@is_packaged = "1"
					@result = package_send(package)
					@err_msg = @result["err_msg"] if !@result["err_msg"].blank?				
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
		# binding.pry
		result = package_send(@package)
		
		respond_to do |format|
			if !result["err_msg"].blank?
				flash[:alert] = result["err_msg"]
			else
				flash[:message] = "获取邮件号、格口码成功"
			end
      format.html { redirect_to request.referer }
      format.json { head :no_content }
    end
	end

	def package_send(package)
		result = {}
		interface_sender = XydInterfaceSender.order_create_interface_sender_initialize(package)
		interface_sender.interface_send(10)
		if interface_sender.status.eql?"success"
			result["express_no"] = "e001"#package.express_no
			result["route_code"] = "r001"#package.route_code
		elsif interface_sender.status.eql?"failed"
			if interface_sender.error_msg.blank?
				if interface_sender.last_response.include?""
					result["err_msg"] = "该地区属于疫区，不允许邮寄"
				end
			elsif interface_sender.error_msg.include?"Timeout"
				result["err_msg"] = "超时,获取邮件号失败"
			end
		end	
		return result			
	end

	private

	def package_params
    params[:package].permit(:package_no, :express_no, :route_code, :status, :packed_at,  :user_id, :order_list, :bag_list)
  end

end
