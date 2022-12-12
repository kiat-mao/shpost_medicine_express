class OrdersController < ApplicationController
  load_and_authorize_resource :order
  skip_before_action :verify_authenticity_token
  
  # GET /orders
  # GET /orders.json
  def index
    @orders_grid = initialize_grid(@orders.accessible_by(current_ability),
         :order => 'order_no',
         :order_direction => 'asc', 
         :per_page => params[:page_size])
  end

  def edit
  end

  def show
  end

	def update
    respond_to do |format|
      if @order.update(order_params)
        @order.update no_modify: true
        format.html { redirect_to @order, notice: I18n.t('controller.update_success_notice', model: '订单')}
        format.json { head :no_content }
      else
        format.html { render action: 'edit' }
        format.json { render json: @order.errors, status: :unprocessable_entity }
      end
    end
  end

  def other_province_index
  	@orders = @orders.accessible_by(current_ability).where(status: "waiting", no_modify: false)

  	@selected = params[:selected].blank? ? 'false' : params[:selected]
    if !@selected.blank? && @selected.eql?('true')
      @orders = @orders.where("(receiver_province not like (?) or receiver_province = ? or receiver_city = ? or receiver_district = ?) and no_modify = ?", "上海%", nil, nil, nil, false)
    end

    @orders_grid = initialize_grid(@orders,
         :order => 'order_no',
         :order_direction => 'asc', 
         :per_page => params[:page_size])
  end

  def order_report
  	@create_at_start = !params[:create_at_start].blank? ? params[:create_at_start] : nil
    @create_at_end = !params[:create_at_end].blank? ? params[:create_at_end] : nil
    @results = nil

    unless request.get?
      if @create_at_start.blank? && @create_at_end.blank?
      	flash[:alert] = "请选择订单日期"
        redirect_to request.referer
      else
      	@results = init_result(@create_at_start, @create_at_end)
	    end
    end
  end

  def order_report_export
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
    sheet1[0,0] = "订单日期：#{create_at_start}至#{create_at_end}"

    sheet1.row(2).default_format = title
    sheet1.row(2).concat %w{医院名称 数量}
    
    count_row = 3
    
    results.each do |x|
      sheet1[count_row,0] = x[0]
      sheet1[count_row,1] = x[1]

      0.upto(1) do |x|
        sheet1.row(count_row).set_format(x, body)
      end 

      count_row += 1
    end

    book.write xls_report  
    xls_report.string
  end

  def init_result(create_at_start, create_at_end)
  	orders = Order.accessible_by(current_ability).where(status: "waiting")

    if !create_at_start.blank?
      orders = orders.where("created_at >= ?", to_date(create_at_start))
    end

    if !create_at_end.blank?
      orders = orders.where("created_at <= ?", to_date(create_at_end)+1.minute)
    end
    results = orders.group(:hospital_name).count
  end

  def to_date(time)
    date = Date.civil(time.split(/-|\//)[0].to_i,time.split(/-|\//)[1].to_i,time.split(/-|\//)[2].to_i)
    return date
  end

  def set_no_modify
    if params[:grid] && params[:grid][:selected]
      selected = params[:grid][:selected]
         
      until selected.blank? do 
        orders = Order.where(id:selected.pop(1000))
        orders.each do |o|
          o.update no_modify: true
        end
      end
      flash[:notice] = "已设置成功"      
    else
      flash[:alert] = "请勾选订单"
    end   
    
    respond_to do |format|
      format.html { redirect_to request.referer }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_order
      @order = Order.find(params[:id])
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def order_params
      params.require(:order).permit(:receiver_province, :receiver_city, :receiver_district, :receiver_addr)
    end
end