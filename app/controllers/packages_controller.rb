class PackagesController < ApplicationController
  load_and_authorize_resource :package
  protect_from_forgery :except => [:tkzd,:zxqd]

  # GET /packages
  # GET /packages.json
  def index
    @packages_grid = initialize_grid(@packages.accessible_by(current_ability), :per_page => params[:page_size])
  end

  def tkzd
  	@package = nil

  	if !params[:package_id].blank?
  		@package = Package.find(params[:package_id])
  	end
  end

	def zxqd
		@package = nil

  	if !params[:package_id].blank?
  		@package = Package.find(params[:package_id])
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
  	@package_id = nil
  	@is_packaged = "0"

  	if !@order_bags.blank?
	  	uneql_order_no = uneql_order_no(@order_bags)
	  	if !uneql_order_no.blank?
	  		@err_msg = "订单号#{uneql_order_no}，有袋子未扫描"
	  	else
	  		# get_express_no_route_code    #从新一代获取
	  		@express_no = "e000001"
	  		@route_code = "r000001"
	  		if false
	  			@err_msg = "获取邮件号失败/该地区属于'疫区‘，不允许邮寄"
	  		else
  				package_no = Package.new_package_no(current_user)
  				package = Package.create package_no: package_no, express_no: @express_no, route_code: @route_code, status: 'waiting', packed_at: Time.now, user_id: current_user.id
  				@package_id = package.id
  				@is_packaged = "1"
  				Order.where(order_no: get_orders(@order_bags)).update_all package_id: package.id, status: "packaged"
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
		order_nos = []
		
		order_bags.split("|").each do |o|
			order_nos << o.split(":")[0]
		end
		return order_nos
	end

end
