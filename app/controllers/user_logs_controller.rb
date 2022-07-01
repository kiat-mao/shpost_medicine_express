class UserLogsController < ApplicationController
 load_and_authorize_resource

  # GET /user_logs
  # GET /user_logs.json
  def index
    @user_logs_grid = initialize_grid(@user_logs, 
      :order => 'user_logs.id',
      :order_direction => 'desc',
    	include: :user,
      :per_page => params[:page_size])
  end

  # GET /user_logs/1
  # GET /user_logs/1.json
  def show
  end

  # DELETE /user_logs/1
  # DELETE /user_logs/1.json
  def destroy
    # @user_log.orders.each do |o|
    #   if o.blank?
    #     next
    #   else
    #     if o.status.eql? "waiting"
    #       o.destroy
    #     end
    #   end
    # end
    
    @user_log.destroy
    respond_to do |format|
      format.html { redirect_to user_logs_url }
      format.json { head :no_content }
    end
  end


end
