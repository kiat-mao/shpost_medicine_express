class StandardInterface
  def self.mail_push(context, business, unit)
    mail_no = context["MAIL_NO"]
    mail_date = context["MAIL_DATE"]
    if mail_date.blank?
      mail_date = Date.today
    else
      mail_date = Time.parse(mail_date)
    end
    postal_code = context["POSTAL_CODE"]
    business_code = context["BUSINESS_CODE"]
    
    ActiveRecord::Base.transaction do
      query_result = QueryResult.find_by(registration_no: mail_no, business: business)
      raise "该邮件号已被其他商户占用" if !query_result.blank? && !query_result.business.eql?(business)

      if query_result.blank?
        # raise "该邮件号已被其他商户占用" if QueryResult.where.not(business: business).find_by(registration_no: mail_no).try(:exists?)
        query_result = QueryResult.create!(registration_no: mail_no, postcode: postal_code, order_date: mail_date, unit: unit, business: business, business_code: business_code, status: QueryResult::STATUS[:waiting])
      else
        query_result.update!(postcode: postal_code, business_code: business_code)
      end

      return query_result
    end 
  end

  def self.mail_query(context, business, unit)
    mail_no = context["MAIL_NO"]

    query_result = QueryResult.find_by(registration_no: mail_no, business: business)
    raise "无该邮件信息" if query_result.blank?

    status = query_result.status.eql?(QueryResult::STATUS[:waiting]) && query_result.is_posting? ? "posting" : query_result.status

    mail_json = {"MAIL_NO" => query_result.registration_no, "STATUS" => status, "RESULT_MSG" => query_result.result, "OPERATED_AT" => query_result.operated_at.try(:strftime, '%Y%m%d'), "QUERIED_AT" => query_result.query_date.try(:strftime, '%Y%m%d%H%M')}
  end

  def self.mail_query_in_time(context, business, unit)
    mail_no = context["MAIL_NO"]

    interface_sender = JdptInterface.jdpt_trace_in_time mail_no, business

    # if ! interface_sender.try(:status).eql? InterfaceSender::STATUS[:success]
    interface_sender.interface_send
    # end
    if interface_sender.reload.status.eql? InterfaceSender::STATUS[:success]
      last_result = JdptInterface.parse_last_result(interface_sender.reload.last_response)
    

    status = last_result["status"].eql?(QueryResult::STATUS[:waiting]) && last_result["is_posting"] ? "posting" : last_result["status"]

    mail_json = {"MAIL_NO" => mail_no, "STATUS" => status, "RESULT_MSG" =>  last_result["opt_desc"], "OPERATED_AT" => last_result["opt_at"].try(:to_time).try(:strftime, '%Y%m%d%H%M'), "QUERIED_AT" => Time.now.strftime('%Y%m%d%H%M'), "QUERY_MSG" => interface_sender.last_response}
    else
      raise '新一代跟踪查询接口调用失败'
    end
  end


  def self.mail_query_in_local(context, business, unit)
    mail_no = context["MAIL_NO"]

    mail_trace = MailTrace.find_by mail_no: mail_no

    raise "无该邮件信息" if mail_trace.blank?

    if ! mail_trace.blank?
      status = mail_trace.status.eql?(QueryResult::STATUS[:waiting]) && mail_trace.is_posting? ? "posting" : mail_trace.status

      mail_json = {"MAIL_NO" => mail_trace.mail_no, "STATUS" => mail_trace.status, "RESULT_MSG" => mail_trace.result, "OPERATED_AT" => mail_trace.operated_at.try(:strftime, '%Y%m%d%H%M'), "QUERIED_AT" => mail_trace.last_received_at.try(:strftime, '%Y%m%d%H%M'), "QUERY_MSG" => mail_trace.jdpt_traces}
    end
  end
end
