class StandardInterfaceController < ApplicationController
  around_action :interface_around
  skip_before_action :authenticate_user!
  skip_before_action :verify_authenticity_token

  def order_push
    begin
      Order.order_push(@context_hash)
    rescue Exception => e
      out_error e
      return error_builder('9999', e.message)
    end
    return success_builder
  end

  private
  def interface_around
    begin
      verify_params
      if ! @status.eql? false
        yield
      end
    ensure
      # binding.pry
      InterfaceLog.log(params[:controller], params[:action], @status ? InterfaceLog::statuses[:success] : InterfaceLog::statuses[:failed], {request_url: request.url, params: params.to_json, response_body: @response, request_ip: request.ip, business_code: @business_no, parent: @object, error_msg: @error_msg, unit: @unit}) if @status.eql? false#if Rails.env.development?
    end
  end

  def verify_params
    @business_no = params[:business]
    return error_builder('0004') if @business_no.blank?

    @unit_no = params[:unit]
    @unit = UNit.find_by_no(@unit_no)
    return error_builder('0003') if @unit.blank?

   
    @context = params[:context]

    begin
      @context_hash = ActiveSupport::JSON.decode(@context)
    rescue Exception => e
      return error_builder('0002')
    end

    return error_builder('0005', "ORDER_NO is null") if @context_hash['ORDER_NO'].blank?

    order = Order.find_by(order_no: @context_hash['ORDER_NO'])

    return error_builder('0005', 'ORDER_NO had packaged') if order.try('packaged?')

    return error_builder('0005', "EC_NO is null") if (unit_no.eql?('0002') && @context_hash['EC_NO'].blank?)
    
    return error_builder('0005', "PACKAGES is null") if @context_hash['PACKAGES'].blank?


    @context_hash['PACKAGES'].each{|x| 
      return error_builder('0005', "PACKAGES_NO #{x} exists")  if ! Bag.where.not(order: order).find_by(bag_no: x).blank?
    }

    return error_builder('0005', "EC_NO is null") if (unit_no.eql?('0002') && @context_hash['EC_NO'].blank?)    

    return error_builder('0005', "ORDER_MODE is null") if (unit_no.eql?('0002') && @context_hash['ORDER_MODE'].blank?)

    return error_builder('0005', "FREIGHT is null") if (unit_no.eql?('0002') && @context_hash['FREIGHT'].blank?)    

    return error_builder('0005', "SENDER_PROVINCE is null") if @context_hash['SENDER_PROVINCE'].blank?

    return error_builder('0005', "SENDER_CITY is null") if @context_hash['SENDER_CITY'].blank?

    return error_builder('0005', "SENDER_DISTRICT is null") if @context_hash['SENDER_DISTRICT'].blank?

    return error_builder('0005', "SENDER_ADDR is null") if @context_hash['SENDER_ADDR'].blank?

    return error_builder('0005', "SENDER_NAME is null") if @context_hash['SENDER_NAME'].blank?

    return error_builder('0005', "SENDER_PHONE is null") if @context_hash['SENDER_PHONE'].blank?

    return error_builder('0005', "RECEIVER_PROVINCE is null") if (unit_no.eql?('0001') && @context_hash['RECEIVER_PROVINCE'].blank?)

    return error_builder('0005', "RECEIVER_CITY is null") if (unit_no.eql?('0001') && @context_hash['RECEIVER_CITY'].blank?)

    return error_builder('0005', "RECEIVER_DISTRICT is null") if (unit_no.eql?('0001') && @context_hash['RECEIVER_DISTRICT'].blank?)

    return error_builder('0005', "RECEIVER_ADDR is null") if @context_hash['RECEIVER_ADDR'].blank?

    return error_builder('0005', "RECEIVER_NAME is null") if @context_hash['RECEIVER_NAME'].blank?

    return error_builder('0005', "RECEIVER_PHONE is null") if @context_hash['RECEIVER_PHONE'].blank?

    # return error_builder('0005', "SITE_NO is null") if @context_hash['SITE_NO'].blank?

    return verify_sign
  end

  def verify_sign
    @date_digest = params[:sign]
    return error_builder('0001') if ! @date_digest.eql? data_digest(@context, '')
  end

  def data_digest(context, secret_key)
    Base64.encode64(Digest::MD5.hexdigest("#{context}#{secret_key}")).strip
  end

  def success_builder
    @status = true
    
    @response = response_builder

    render json: @response, content_type: "application/json"
  end

  def error_builder(error_code, msg = nil)
    @status = false

    @reson = I18n.t("standard_interface.error.#{error_code}")

    @response = response_builder error_code, msg

    Rails.logger.error @response

    render json: @response, content_type: "application/json"
  end

  def response_builder(code = nil, msg = nil)
    return {'FLAG' => @status, 'CODE' => code, 'MSG' => msg.blank? ? @reson : msg }.to_json
  end

  def out_error e
    # puts e.message
    # puts e.backtrace
    @error_msg = "#{e.class.name} #{e.message}"
    Rails.logger.error("#{e.class.name} #{e.message}")
    e.backtrace.each do |x|
       @error_msg += "\n#{x}"
      Rails.logger.error(x)
    end
  end
end
