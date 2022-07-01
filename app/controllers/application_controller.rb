class ApplicationController < ActionController::Base
  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  rescue_from Exception, with: :get_errors if Rails.env.production?

  rescue_from CanCan::AccessDenied, with: :access_denied

  protect_from_forgery with: :exception

  before_action :configure_charsets
  before_action :authenticate_user!

  before_action :configure_permitted_parameters, if: :devise_controller?


  def self.user_logs_filter *args
    after_action args.first.select{|k,v| k == :only || k == :expert} do |controller|
      save_user_log args.first.reject{|k,v| k == :only || k == :expert}
    end
  end

  def save_user_log *args
    if !args.first[:object].blank?
      object = eval("@#{args.first[:object].to_s}")
    end
    
    if !controller_name.singularize.blank?
      object ||= eval("@#{controller_name.singularize}")
    end

    operation = args.first[:operation]
    operation ||= I18n.t("action_2_operation.#{action_name}") + object.class.model_name.human.to_s


    # import_type = eval("@#{args.first[:import_type].to_s}")
    if !args.first[:finish].blank?
      finish = eval("@#{args.first[:finish].to_s}")
    end
    
    symbol = args.first[:symbol]

    # ids = eval("@#{args.first[:ids].to_s}")

    if !args.first[:parent].blank?
      parent = eval("@#{args.first[:parent].to_s}")
    end
    parent ||= object


    if finish.blank? or (!finish.blank? and finish.eql?"1")
      if !parent.blank?
         @user_log = UserLog.new(user: current_user, operation: operation, parent: parent)
      else
         @user_log = UserLog.new(user: current_user, operation: operation)
      end

      if object
        if object.errors.blank?
          @user_log.object_class = object.class.to_s
          @user_log.object_primary_key = object.id

          if symbol && object[symbol.to_sym]
            @user_log.object_symbol = object[symbol.to_sym]
          else
            @user_log.object_symbol = object.id
          end
          
          # if args.first[:operation].eql? "包装出库" 
          #   @user_log.orders = Order.where(id: object.id)
          # end
          # if args.first[:operation].eql? "生成出库单" or args.first[:operation].eql? "确认出库"
          #   @user_log.orders = object.orders
          # end
          
          # if args.first[:operation].eql? "包装出库" 
          #   Order.where(id: object.id).update_all(out_at:@user_log.created_at)
          # end
          # if args.first[:operation].eql?"确认出库"
          #   Order.where(keyclientorder_id: object.id).update_all(out_at:@user_log.created_at)
          # end
      
        end
      end
      @user_log.save!
    end
  end

  def current_ability
    @current_ability ||= Ability.new(current_user)
  end

  def configure_charsets
    headers["Content-Type"]="text/html;charset=utf-8"
  end

  protected

  def configure_permitted_parameters
    devise_parameter_sanitizer.permit(:sign_in, keys: [:username])
  end
     
 private
  def access_denied exception
    @error_title = I18n.t 'errors.access_deny.title', default: 'Access Denied!'
    @error_message = I18n.t 'errors.access_deny.message', default: 'The user has no permission to vist this page'
    render template: '/errors/error_page',layout: false
  end

  def get_errors exception
    # Rails.logger.error(exception)
    Rails.logger.error("#{exception.class.name} #{exception.message}")
    exception.backtrace.each{|x| Rails.logger.error(x)}
    
    @error_title = I18n.t 'errors.get_errors.title', default: 'Get An Error!'
    @error_message = I18n.t 'errors.get_errors.message', default: 'The operation you did get an error'
    render :template => '/errors/error_page',layout: false
  end
end
