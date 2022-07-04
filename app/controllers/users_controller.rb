class UsersController < ApplicationController
  load_and_authorize_resource :unit
  load_and_authorize_resource :user

  user_logs_filter only: [:create, :destroy], symbol: :username#, object: :user, operation: '新增用户'

  # GET /users
  # GET /users.json
  def index
    #@users = User.all
    @users = @users.where(unit: @unit) if ! @unit.blank?
    @users_grid = initialize_grid(@users,
      :per_page => params[:page_size])
  end

  # GET /users/1
  # GET /users/1.json
  def show
  end

  # GET /users/new
  def new
    #@user = User.new
  end

  # GET /users/1/edit
  def edit
  end

  # POST /users
  # POST /users.json
  def create
    respond_to do |format|
      @user.role = 'user'
      if @user.save
        format.html { redirect_to params[:referer], notice: I18n.t('controller.create_success_notice', model: '用户') }
        format.json { render action: 'show', status: :created, location: @user }
      else
        format.html { render action: 'new' }
        format.json { render json: @user.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /users/1
  # PATCH/PUT /users/1.json
  def update
    respond_to do |format|
      if @user.update(user_params)
        format.html { redirect_to params[:referer], notice: I18n.t('controller.update_success_notice', model: '用户') }
        format.json { head :no_content }
      else
        format.html { render action: 'edit' }
        format.json { render json: @user.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /users/1
  # DELETE /users/1.json
  def destroy
    @user.destroy
    respond_to do |format|
      format.html { redirect_to request.referer }
      format.json { head :no_content }
    end
  end

  def to_reset_pwd
  end

  def reset_pwd
    @operation = "reset_pwd"
    respond_to do |format|
      if @user.update(user_params)
        format.html { redirect_to params[:referer], notice: "密码重置成功" }
        format.js { head :no_content }
      else
        format.html { render action: 'to_reset_pwd' }
        format.json { render json: @user.errors, status: :unprocessable_entity }
      end
    end
  end

  def lock
    @user.lock
  end

  def unlock
    @user.unlock  
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    # def set_user
    #   @user = User.find(params[:id])
    # end

    # Never trust parameters from the scary internet, only allow the white list through.
    def user_params
      params[:user].permit(:username, :name, :password, :email, :unit_id,  :role)
    end
end
