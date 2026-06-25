class InterfaceSender < ActiveRecord::Base
  # belongs_to :unit
  # belongs_to :business
  before_save :url_parser

  @@lock = Mutex.new

  STATUS = { waiting: 'waiting', success: 'success', failed: 'failed' }
  INTERFACE_TYPE = {xml: 'xml', http: 'http', soap: 'soap', json: 'json'}
  HTTP_TYPE = {post: 'post', get: 'get'}

  STATUS_SHOW = { success: '成功', failed: '失败', waiting: '待处理' }
  CLASS_NAME = { JDPT: '寄递平台'}
  METHOD_NAME = { TRACE: '运单轨迹信息获取接口'}
  validates_presence_of :url, :interface_code, :message => '不能为空'

  def self.interface_sender_initialize(interface_code, body, *args)
    if ! interface_code.blank?
      interface_sender = InterfaceSender.new(interface_code: interface_code, body: body, send_times: 0, status: STATUS[:waiting], next_time: Time.now)
    
      interface_sender_hash = I18n.t(:InterfaceSender)[interface_code.to_sym]

      if interface_sender_hash.is_a?(Hash)
        interface_sender_hash.each_key do |key|
          if interface_sender.respond_to? "#{key}="
            interface_sender.send "#{key}=", interface_sender_hash[key.to_sym]
          end
        end
      end

      if ! args.first.blank? && args.first.is_a?(Hash)
        args.first.each_key do |key|
          if interface_sender.respond_to? "#{key}="
            interface_sender.send "#{key}=", args.first[key.to_sym]
          end
        end
      end
      
      # interface_sender.set_next_time
      interface_sender.save!
      return interface_sender
    end
  end

  def self.schedule_send_image_push(thread_count = nil)
    i1 = self.where(status: InterfaceSender::STATUS[:waiting]).where('next_time < ?', Time.now).where(interface_code: 'image_push').order(:created_at).limit(200).to_a
    if i1.size < 50
      i2 = self.where(status: InterfaceSender::STATUS[:waiting]).where('next_time < ?', Time.now).where(interface_code: 'obtain_authentic_picture').order(:created_at).limit(200).to_a
    else
      i2 = []
    end
    interface_senders = i1 | i2
    puts "==========InterfaceSender.schedule_send_image_push==========" 
    puts "==========Begin at #{Time.now}=========="
    puts "==========ImagePush: #{i1.size}, ObtainAuthenticPicture: #{i2.size}=========="
     if ! thread_count.blank?
      i = thread_count
    else
      i = interface_senders.size > 5 ? 5 : interface_senders.size
    end
    ts = []
    i.times.each do |x|
      t = Thread.new do
        while interface_senders.size > 0
          is = nil
          @@lock.synchronize do
            is = interface_senders.pop
          end
          if is.blank?
            next
          end

          puts is.id
          is.interface_send
        end
      end
      ts << t
    end
    ts.each do |x|
      x.join
    end
    puts "==========End at #{Time.now}=========="
  end

  def self.schedule_send(thread_count = nil)
    #interface_senders = self.where(status: InterfaceSender::STATUS[:waiting]).where('next_time < ?', Time.now).where(interface_code: 'image_push').order(:created_at).limit(200).to_a
    interface_senders = self.where(status: InterfaceSender::STATUS[:waiting]).where('next_time < ?', Time.now).where.not(interface_code: ['image_push', 'obtain_authentic_picture']).order(:created_at).limit(2000).to_a #if interface_senders.blank?
    if ! thread_count.blank?
      i = thread_count
    else
      i = interface_senders.size > 5 ? 5 : interface_senders.size
    end
    ts = []
    i.times.each do |x|
      t = Thread.new do
        while interface_senders.size > 0
          is = nil
          @@lock.synchronize do
            is = interface_senders.pop
          end
          if is.blank?
            next
          end
          
          puts is.id
          is.interface_send
        end
      end
      ts << t
    end
    ts.each do |x|
      x.join
    end
  end

  # def self.schedule_send
  #   interface_senders = self.where(status: InterfaceSender::STATUS[:waiting]).where('next_time < ?', Time.now).order(:created_at).limit(1000)
  #   i = interface_senders.size > 50 ? 50 : interface_senders.size
  #   50.times.each do
  #     Thread.new{ interface_senders.pop.interface_send until interface_senders.size.eql? 0}.join
  #   end
  #   # interface_senders.each do |x|
  #   #   x.interface_send
  #   # end
  # end

  def interface_send(second = nil)
    response = nil
    begin
      Timeout.timeout(second.blank? ? 30 : second) do
        case self.interface_type
        when INTERFACE_TYPE[:http]
          response = self.http_send
        when INTERFACE_TYPE[:xml]
          response = self.xml_send
        when INTERFACE_TYPE[:json]
          response = self.http_send(true)
        when INTERFACE_TYPE[:soap]
          response = self.soap_send
        else
          response = self.http_send
        end
      end
    rescue Timeout::Error => e
      # 真正的超时异常
      self.error_msg = "请求超时 (超过#{second || 30}秒): #{e.message}"

      puts self.error_msg
      Rails.logger.error self.error_msg

      response = '' if response.nil?
      self.fail! response
      return
    rescue Exception => e
      # 其他异常（网络错误、解析错误等）
      error_title = "http_send 发生异常: #{self.interface_code}: #{self.id}  #{e.class} - #{e.message}"
      error_msg = e.backtrace.join("\n")
      
      puts error_title
      puts error_msg
      Rails.logger.error error_title
      Rails.logger.error error_msg

      self.error_msg = "#{e.class.name} #{e.message} \n#{e.backtrace.join("\n")}"

      response = '' if response.nil?
      self.fail! response
      return
    end

    # 如果响应为空，但未发生异常，则视为业务返回空（非超时）
    if response.blank?
      self.error_msg = "服务端返回空响应"
      response = ''
      self.fail! response
      return
    end

    # 正常回调
    self.callback response
  end

  def interface_rebuild
    if !self.object_class.blank? && !self.object_id.blank?
      object_class = self.object_class.constantize
      object = object_class.find_by id: self.object_id
      if !object.blank?
        case self.callback_class
        when "YitongInterface"
          inorders = Order.where(big_packet: object)
          params = YitongInterface.setPackageSendParams(inorders)
          self.body = params.to_json
        when "WISHInterface"
          case self.callback_method
          when "parseInorder"
            x = [object]
            xml = WISHInterface.set_inorder(x)
            self.body = xml
          when "parsePostTrack"
            xml_post = WISHInterface.set_post_track(object)
            self.body = xml_post
          end
        when "Swtd"
          self.body = Swtd.setOrderPost(object)
        end
        self.save
      end
    end
  end

  def callback response
    if self.callback_class.blank? || ! self.callback_class.constantize.respond_to?(self.callback_method.to_sym) || self.callback_class.constantize.send(self.callback_method.to_sym, response, (self.callback_params.blank? ? self.callback_params : JSON.parse(self.callback_params)))

      self.succeed! response
    else
      self.fail! response
    end
  end

  def succeed! response
    self.last_response = response.respond_to?(:force_encoding) ? response.force_encoding("UTF-8") : ''
    self.last_time = Time.now
    self.send_times += 1
    self.success
    self.save!
  end

  def fail! response
    self.last_response = response.respond_to?(:force_encoding) ? response.force_encoding("UTF-8") : ''
    self.last_time = Time.now
    self.send_times += 1

    if self.send_times >= (self.max_times || 5)
      self.next_time = nil
      self.failed
    else
      self.set_next_time
      self.waiting
    end
    self.save!
  end

  def set_next_time
    self.next_time = Time.now + (self.interval || 600)
  end

  # def self.unfinished_count(storage)
  #   count = InterfaceSender.where(storage_id: storage,status:"failed").where("interface_senders.created_at >= '#{DateTime.parse((Time.now-1.month).to_s).strftime('%Y-%m-%d').to_s}' and interface_senders.created_at<= '#{DateTime.parse(Time.now.to_s).strftime('%Y-%m-%d').to_s}'").count
  # end

  # private
  def url_parser
    if ! url.blank?
      send_url = URI.parse(self.url)
      self.host = send_url.host
      self.port = send_url.port
    end
  end

  def xml_send
    send_url = URI.parse(self.url)
    request = Net::HTTP::Post.new(send_url.path)
    request.content_type = 'application/octet-stream'
    request.body = self.body
    response = Net::HTTP.start(send_url.host, send_url.port) {|http| http.request(request)}
    response.body
  end

  def http_send is_json = false
    send_url = URI.parse(self.url)
    http_type = self.http_type.presence || 'post'
    
    body = self.body.presence || ''
    header = self.header.blank? ? {} : JSON.parse(self.header)
    header['Content-Type'] ||= 'application/json'
    
    # 使用 HTTPClient，但捕获异常并重新抛出
    client = HTTPClient.new
    client.connect_timeout = 25
    client.send_timeout = 25
    client.receive_timeout = 25
    
    response = case http_type
              when 'post' then client.post(send_url, body, header)
              when 'get'  then client.get(send_url, header)
              else raise "不支持的 HTTP 方法: #{http_type}"
              end
    
    response.body || ''
  rescue => e
    raise  # 重新抛出异常
  end

  def soap_send
    
  end

  def success
    self.status = STATUS[:success]
    return true
  end

  def failed
    if ! self.status.eql? STATUS[:success]
      self.status = STATUS[:failed]
      return true
    else
      return false
    end
  end

  def waiting
    if ! self.status.eql? STATUS[:success]
      self.status = STATUS[:waiting]
      return true
    else
      return false
    end
  end
end
