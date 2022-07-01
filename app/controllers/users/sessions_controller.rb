class Users::SessionsController < Devise::SessionsController

  def create
  	puts "Users::SessionsController start"
    super do |resource|
      puts "test Users::SessionsController"
      # @user_log = UserLog.create(user: current_user, operation: '用户登录')

    end
    puts "Users::SessionsController end"
  end

  def destroy
  	# @user_log = UserLog.create(user: current_user, operation: '用户退出')
  	super do |resource|
  		# session[:current_storage] = nil
  	end
  end

end