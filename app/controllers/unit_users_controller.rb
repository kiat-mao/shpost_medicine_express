class UnitUsersController < ApplicationController
  # before_action :find_unit, only: [:index, :show, :new, :edit, :create, :update, :destroy]
  load_and_authorize_resource :unit
  load_and_authorize_resource :user, through: :unit, parent: false

  user_logs_filter only: [:create, :destroy], object: :user, symbol: :username
  #skip_load_resource :user, :only => :create

  # GET /users
  # GET /users.json
  def index
    #@users = User.all
    @users_grid = initialize_grid(@users)
  end

  # GET /users/1
  # GET /users/1.json
  def show
  end

  # GET /users/new
  def new
  end

  # GET /users/1/edit
  def edit
  end

  # POST /users
  # POST /users.json
  def create
    respond_to do |format|
      if @user.save
        format.html { redirect_to unit_user_path(@unit,@user), notice: I18n.t('controller.create_success_notice', model: '用户') }
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
      if @user.update(unituser_params)
        format.html { redirect_to unit_user_path(@unit,@user), notice: I18n.t('controller.update_success_notice', model: '用户') }
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
      format.html { redirect_to unit_users_path(@unit) }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    # def set_user
    #   @user = User.find(params[:id])
    # end

    # Never trust parameters from the scary internet, only allow the white list through.
    # def find_unit
    #   @unit = Unit.find(params[:unit_id])
    # end 
    
    def user_params
      params[:user].permit(:username, :name, :password, :email, :role)
    end 
end
