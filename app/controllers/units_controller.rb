class UnitsController < ApplicationController
  load_and_authorize_resource :unit

  # GET /units
  # GET /units.json
  def index
    #@unit = Unit.all
    @units_grid = initialize_grid(@units.where(parent_id: params[:id]), :per_page => params[:page_size])
  end

  # def child_units
  #   @parentid = params[:id]
  #   @unit = Unit.new
  # end

  # GET /units/1
  # GET /units/1.json
  def show
  end

  # GET /units/new
  def new
    # @parent_id = params[:id]
    # @parent_unit = Unit.find(@parent_id) if ! @parent_id.blank?
    @unit.parent_id = params[:id]
  end

  # GET /units/1/edit
  def edit
  end

  # POST /units
  # POST /units.json
  def create
    @unit = Unit.new(unit_params)
    respond_to do |format|
      # @unit.unit_type = 'branch'
       if @unit.save
        format.html { redirect_to params[:user][:referer], notice: I18n.t('controller.create_success_notice', model: '单位')}
        format.json { render action: 'show', status: :created, location: @unit }
      else
        format.html { render action: 'new' }
        format.json { render json: @unit.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /units/1
  # PATCH/PUT /units/1.json
  def update
    respond_to do |format|
      if @unit.update(unit_params_4_update)
        format.html { redirect_to params[:user][:referer], notice: I18n.t('controller.update_success_notice', model: '单位') }
        format.json { head :no_content }
      else
        format.html { render action: 'edit' }
        format.json { render json: @unit.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /units/1
  # DELETE /units/1.json
  def destroy
    if @unit.can_destroy?
      @unit.destroy
    else
      flash[:alert] = " 该区分公司下存在子公司或用户，不可删除。"
    end
    respond_to do |format|
      format.html { redirect_to request.referer }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    #def set_unit
      #@unit = Unit.find(params[:id])
    #end

    # Never trust parameters from the scary internet, only allow the white list through.
    def unit_params
      params.require(:unit).permit(:no, :name, :desc, :short_name, :level, :parent_id, :unit_type)
    end

    def unit_params_4_update
      params.require(:unit).permit(:no, :name, :desc, :short_name, :unit_type)
    end
end
