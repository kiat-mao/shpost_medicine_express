class XydInterfaceSender < ActiveRecord::Base
  def self.address_parsing_schedule
    xydConfig = Rails.application.config_for(:xyd)
    gy_unit_no = I18n.t('unit_no.gy').to_s
    gy_units = Unit.where no: gy_unit_no
    orders = Order.where(address_status: :address_waiting, unit: gy_units)
    orders.each_with_index do |order, _i|
      address_parsing_interface_sender_initialize order
    end
  end

  def self.order_create_interface_sender_initialize(package)
    xydConfig = Rails.application.config_for(:xyd)
    body = order_create_request_body_generate(package, xydConfig)
    args = {}
    callback_params = {}
    callback_params['package_id'] = package.id
    args[:callback_params] = callback_params.to_json
    args[:url] = xydConfig[:order_create_url]
    args[:parent_id] = package.id
    args[:unit_id] = package.unit_id
    args[:next_time] = Time.now + 600
    InterfaceSender.interface_sender_initialize('xyd_order_create', body, args)
  end

  def self.order_create_request_body_generate(package, xydConfig)
    now_time = Time.new

    params = {}
    head = {}
    head['system_name'] = xydConfig[:oc_system_name]
    head['req_time'] = now_time.strftime('%Y%m%d%H%M%S%L')
    head['req_trans_no'] = xydConfig[:oc_system_name] + head['req_time']
    signature = Digest::MD5.hexdigest('system_name' + head['system_name'] + 'req_time' + head['req_time'] + 'req_trans_no' + head['req_trans_no'] + xydConfig[:oc_pwd])
    head['signature'] = signature
    params['head'] = head
    body = {}
    body['ecCompanyId'] = xydConfig[:ecCompanyId]
    body['parentId'] = xydConfig[:parentId]
    order = {}
    order['created_time'] = now_time.strftime('%Y-%m-%d %H:%M:%S')
    order['logistics_provider'] = xydConfig[:logistics_provider]
    order['ecommerce_no'] = xydConfig[:ecommerce_no]
    order['ecommerce_user_id'] = now_time.strftime('%Y%m%d%H%M%S%L')
    order['inner_channel'] = xydConfig[:inner_channel]
    order['logistics_order_no'] = 'package' + package.package_no

    o = package.orders.first
    # 20221115 区分国药上药
    if I18n.t('unit_no.gy').to_s == package.unit.no
      unless xydConfig[:sender_no].nil?
        order['sender_no'] = xydConfig[:gy_sender_no]
        order['sender_type'] = '1'
      end
      if o.freight == true
        order['base_product_no'] = xydConfig[:base_product_no_3]
        order['payment_mode'] = xydConfig[:payment_mode_2]

        if o.pay_mode.eql? '10'
          order['biz_product_no'] = xydConfig[:biz_product_no_1]
        elsif o.pay_mode.eql? '11'
          order['biz_product_no'] = xydConfig[:biz_product_no_2]
        end
      else
        order['base_product_no'] = xydConfig[:base_product_no_1]

        if o.pay_mode.eql? '11'
          order['biz_product_no'] = xydConfig[:biz_product_no_3]
        end
      end

      #保价
      insurance_amount = package.orders.sum(:valuation_amount)

      if insurance_amount > 0
        order['insurance_flag'] = '2'
        order['insurance_amount'] = insurance_amount
      end 
    else
      unless xydConfig[:sender_no].nil?
        order['sender_no'] = xydConfig[:sy_sender_no]
        order['sender_type'] = '1'
      end
      order['base_product_no'] = xydConfig[:base_product_no_1]
    end
    sender = {}
    receiver = {}
    sender['name'] = o.sender_name
    sender['mobile'] = o.sender_phone
    sender['prov'] = o.sender_province
    sender['city'] = o.sender_city
    sender['county'] = o.sender_district
    sender['address'] = o.sender_addr
    receiver['name'] = o.receiver_name
    receiver['mobile'] = o.receiver_phone
    receiver['prov'] = o.receiver_province
    receiver['city'] = o.receiver_city
    receiver['county'] = o.receiver_district
    receiver['address'] = o.receiver_addr
    order['sender'] = sender
    order['receiver'] = receiver
    body['order'] = order
    params['body'] = body

    params.to_json
  end

  def self.get_response_message(interfaceSender)
    puts 'get_response_message!!'
    return '空的InterfaceSender对象' if interfaceSender.nil?

    # 优先显示last_response信息,其次是error_msg信息
    last_response_string = interfaceSender.last_response
    if !last_response_string.nil?
      last_response = JSON.parse last_response_string
      head = last_response['head']
      return '不是新一代InterfaceSender对象' if head.nil?

      error_code = head['error_code']
      error_msg = head['error_msg']
      return '成功' if error_code == '0'

      error_msg

    else
      error_message = interfaceSender.error_msg
      return '未发送' if error_message.nil?

      error_message.split("\n")[0]

    end
  end

  def self.order_create_callback_method(response, callback_params)
    puts 'order_create_callback_method!!'
    package_id = nil
    express_no = nil
    route_code = nil
    if callback_params.nil?
      puts 'callback_params:'
    else
      puts 'callback_params:' + callback_params.to_s
      package_id = callback_params['package_id']
    end
    if response.nil?
      puts 'response:'
      puts '运单号:'
      puts '分拣码:'
      false
    else
      puts 'response:' + response
      resJSON = JSON.parse response
      resHead = resJSON['head']
      error_code = resHead['error_code']
      if error_code == '0'
        resBody = resJSON['body']
        express_no = resBody['wayBillNo']
        route_code = resBody['routeCode']
        if !package_id.nil? && package_id.is_a?(Numeric)
          Package.find(package_id).update(express_no: express_no, route_code: route_code, sorting_code: Package.get_sorting_code(route_code))
          puts '运单号:' + express_no.to_s
          puts '分拣码:' + route_code.to_s
          return true
        end
      end
      false
    end
  end

  def self.address_parsing_interface_sender_initialize(order)
    xydConfig = Rails.application.config_for(:xyd)
    body = address_parsing_request_body_generate(order, xydConfig)
    args = {}
    callback_params = {}
    callback_params['order_id'] = order.id
    args[:callback_params] = callback_params.to_json
    args[:url] = xydConfig[:address_parsing_url]
    args[:parent_id] = order.id
    args[:unit_id] = order.unit_id
    InterfaceSender.interface_sender_initialize('xyd_address_parsing', body, args)
    order.update(address_status: :address_parseing)
  end

  def self.address_parsing_request_body_generate(order, xydConfig)
    now_time = Time.new

    params = {}
    head = {}
    head['system_name'] = xydConfig[:ap_system_name]
    head['req_time'] = now_time.strftime('%Y%m%d%H%M%S%L')
    head['req_trans_no'] = xydConfig[:ap_system_name] + head['req_time']
    signature = Digest::MD5.hexdigest('system_name' + head['system_name'] + 'req_time' + head['req_time'] + 'req_trans_no' + head['req_trans_no'] + xydConfig[:ap_pwd])
    head['signature'] = signature
    params['head'] = head
    body = {}
    body['salt'] = xydConfig[:ap_salt]
    addresses = []
    address = {}
    address['address'] = order.receiver_addr
    addresses << address
    body['addresses'] = addresses
    params['body'] = body

    params.to_json
  end

  def self.address_parsing_callback_method(response, callback_params)
    return false if callback_params.blank? || response.blank?

    # 判断order是否存在,是否不可修改
    begin
      order = Order.find callback_params['order_id']
    rescue StandardError => e
      Rails.logger.error e.message
      return false
    ensure
      if order.no_modify
        order.address_success!
        return true
      end
    end

    resJSON = JSON.parse response
    error_code = resJSON['head']['error_code']

    if ! error_code.eql? '0'
			order.address_failed!
      return true
    end

    address = resJSON['body']['results'][0]
    res_code = address['resCode']
    if res_code.eql? '0000'
      order.receiver_province = address['provName']
      order.receiver_city = address['cityName']
      order.receiver_district = address['countyName']

      if order.receiver_province.blank? || order.receiver_city.blank? || order.receiver_district.blank?
        order.address_failed!
      else
        order.address_success!
      end

      true
    else
      order.address_failed!
      false
    end
  end

  
  def self.obtain_authentic_picture_interface_sender_initialize(authentic_picture)
    xydConfig = Rails.application.config_for(:xyd)
    body = obtain_authentic_picture_request_body_generate(authentic_picture, xydConfig)
    args = {}
    callback_params = {}
    callback_params['authentic_picture_id'] = authentic_picture.id
    args[:callback_params] = callback_params.to_json
    args[:url] = xydConfig[:obtain_authentic_picture_url]
    args[:parent_id] = authentic_picture.id
    InterfaceSender.interface_sender_initialize('obtain_authentic_picture', body, args)
    # order.update(address_status: :address_parseing)#要改
  end

  def self.obtain_authentic_picture_request_body_generate(authentic_picture, xydConfig)
    now_time = Time.new

    params = {}
    head = {}
    head['system_name'] = xydConfig[:ap_system_name]
    head['req_time'] = now_time.strftime('%Y%m%d%H%M%S%L')
    head['req_trans_no'] = xydConfig[:ap_system_name] + head['req_time']
    signature = Digest::MD5.hexdigest('system_name' + head['system_name'] + 'req_time' + head['req_time'] + 'req_trans_no' + head['req_trans_no'] + xydConfig[:ap_pwd])
    head['signature'] = signature
    params['head'] = head
    body = {}
    data = {}
    data['waybillNo'] = authentic_picture.express_no
    data['authenticType'] = "2"
    data['channelName'] = xydConfig[:channelName]
    
    body['data'] = data
    params['body'] = body

    params.to_json
  end

  def self.obtain_authentic_picture_callback_method(response, callback_params)
    return false if callback_params.blank? || response.blank?

    # 判断authentic_picture是否存在,是否不可修改
    begin
      authentic_picture = AuthenticPicture.waiting.find callback_params['authentic_picture_id']
    rescue StandardError => e
      Rails.logger.error e.message
      return false
    end

    resJSON = JSON.parse response
    error_code = resJSON['head']['error_code']

    if ! error_code.eql? '0'
			authentic_picture.failed!
      return false
    end
    
    image = resJSON['body']['image']
    if ! image.blank?
      # 转发图片
      context = {'ORDER_NO': authentic_picture.express_no, 'IMAGE': image}.to_json

      secret_key = ''

      sign = Base64.encode64(Digest::MD5.hexdigest("#{context}#{secret_key}")).strip

      body = {'context': context, 'business': '0001', 'unit': '0001', 'format': 'json', 'sign': sign}.to_json

      i= InterfaceSender.interface_sender_initialize('image_push', body)

      i.interface_send
      
      
      authentic_picture.sended!

      return true
    end

    return false 
  end
  
end
